import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/auth/data/auth_remote_source.dart';
import 'package:gnosis_chat/features/auth/data/auth_repository.dart';
import 'package:gnosis_chat/features/auth/data/user_cache.dart';
import 'package:gnosis_chat/features/auth/domain/auth_state.dart' as app;
import 'package:gnosis_chat/features/auth/domain/social_provider.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/conversation_provider.dart';
import 'package:gnosis_chat/services/api/api_client.dart';
import 'package:gnosis_chat/services/iap/revenue_cat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:url_launcher/url_launcher.dart';

final authProvider = StateNotifierProvider<AuthNotifier, app.AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final userCache = ref.watch(userCacheProvider);
  return AuthNotifier(AuthRemoteSource(api.dio, userCache), userCache, ref);
});

class AuthNotifier extends StateNotifier<app.AuthState> {
  AuthNotifier(this._repo, UserCache userCache, this._ref)
      : super(_computeInitialState(userCache)) {
    _initAuthListener();
    _startPeriodicSessionCheck();
  }

  final AuthRepository _repo;
  final Ref _ref;
  StreamSubscription<sb.AuthState>? _supabaseListener;
  Timer? _periodicCheckTimer;

  static app.AuthState _computeInitialState(UserCache userCache) {
    final session = sb.Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final cachedUser = userCache.loadUser();
      if (cachedUser != null) {
        return app.AuthState.authenticated(cachedUser);
      }
    }
    return const app.AuthState.initial();
  }

  void _initAuthListener() {
    // 1. Initial check for existing session
    final initialSession = sb.Supabase.instance.client.auth.currentSession;
    if (initialSession != null) {
      ensureValidSessionAndRefresh();
    }

    _supabaseListener = sb.Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final session = data.session;
      final event = data.event;
      debugPrint(
        '!!!!! GNOSIS AUTH EVENT: $event, Session: ${session != null}',
      );

      if (event == sb.AuthChangeEvent.signedIn) {
        try {
          if (!kIsWeb) {
            await closeInAppWebView();
          }
        } catch (e) {
          debugPrint('Error closing in-app webview: $e');
        }
      }

      if (event == sb.AuthChangeEvent.signedOut) {
        state = const app.AuthState.unauthenticated();
        return;
      }

      if (session != null) {
        if (event == sb.AuthChangeEvent.signedIn ||
            event == sb.AuthChangeEvent.tokenRefreshed ||
            event == sb.AuthChangeEvent.userUpdated ||
            event == sb.AuthChangeEvent.initialSession) {
          fetchUser();
        } else {
          final isAuth = state.maybeMap(
            authenticated: (_) => true,
            orElse: () => false,
          );
          if (!isAuth) {
            fetchUser();
          }
        }
      }
    });
  }

  void _startPeriodicSessionCheck() {
    _periodicCheckTimer?.cancel();
    // Check session health every 5 minutes
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final session = sb.Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final expiresAt = session.expiresAt;
        // If expired or expiring in less than 5 minutes (300s)
        if (session.isExpired || (expiresAt != null && expiresAt - nowSeconds < 300)) {
          debugPrint('AUTH: Proactive periodic token refresh triggered');
          ensureValidSessionAndRefresh();
        }
      }
    });
  }

  /// Called when the app resumes from background or tab gains focus
  Future<void> onAppResumed() async {
    debugPrint('AUTH: App resumed from background. Syncing session health...');
    await ensureValidSessionAndRefresh();
  }

  /// Proactively ensures the token is fresh and syncs user profile & conversations.
  Future<void> ensureValidSessionAndRefresh() async {
    try {
      final session = sb.Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final expiresAt = session.expiresAt;
        if (session.isExpired || (expiresAt != null && expiresAt - nowSeconds < 120)) {
          debugPrint('AUTH: Session expired/near expiry. Refreshing session...');
          await sb.Supabase.instance.client.auth.refreshSession();
        }
      }
      await fetchUser();
    } on sb.AuthException catch (e) {
      debugPrint('AUTH: AuthException in ensureValidSessionAndRefresh: $e');
      if (e.message.contains('Refresh Token') ||
          e.code == 'refresh_token_not_found' ||
          e.statusCode == '400') {
        debugPrint('AUTH: Refresh token invalid or not found. Resetting session...');
        await _repo.logout();
        if (mounted) {
          state = const app.AuthState.unauthenticated();
        }
      }
    } catch (e) {
      debugPrint('AUTH: Error during ensureValidSessionAndRefresh: $e');
    }
  }

  Future<void> fetchUser() async {
    debugPrint('AUTH: Fetching user profile...');
    try {
      final user = await _repo.getCurrentUser();
      if (user != null && mounted) {
        debugPrint('AUTH: Profile obtained. Plan: ${user.plan}, Avatar: ${user.avatarUrl}');
        RevenueCatService.logIn(user.id);
        state = app.AuthState.authenticated(user);
      } else {
        debugPrint('AUTH: Fetch skipped (user null or unmounted)');
      }
    } on sb.AuthException catch (e) {
      debugPrint('AUTH: AuthException in fetchUser: $e');
      if (e.message.contains('Refresh Token') ||
          e.code == 'refresh_token_not_found' ||
          e.statusCode == '400') {
        debugPrint('AUTH: Dead token in fetchUser. Resetting to unauthenticated...');
        await _repo.logout();
        if (mounted) {
          state = const app.AuthState.unauthenticated();
        }
        return;
      }
      if (mounted) {
        state = app.AuthState.error(e.message);
      }
    } catch (e) {
      debugPrint('AUTH: ERROR in fetchUser: $e');
      // If error might be due to stale token, attempt one fresh recovery refresh
      final session = sb.Supabase.instance.client.auth.currentSession;
      if (session != null) {
        try {
          debugPrint('AUTH: Attempting recovery session refresh...');
          await sb.Supabase.instance.client.auth.refreshSession();
          final retryUser = await _repo.getCurrentUser();
          if (retryUser != null && mounted) {
            state = app.AuthState.authenticated(retryUser);
            return;
          }
        } on sb.AuthException catch (authErr) {
          if (authErr.message.contains('Refresh Token') ||
              authErr.code == 'refresh_token_not_found') {
            await _repo.logout();
            if (mounted) {
              state = const app.AuthState.unauthenticated();
            }
            return;
          }
        } catch (_) {}
      }

      // If we already have a cached/authenticated user, keep it rather than degrading to error
      final isAlreadyAuth = state.maybeMap(
        authenticated: (_) => true,
        orElse: () => false,
      );
      if (!isAlreadyAuth && mounted) {
        state = app.AuthState.error(e.toString());
      }
    }
  }

  @override
  void dispose() {
    _supabaseListener?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> signInWithProvider(SocialProvider provider) async {
    state = const app.AuthState.loading();
    try {
      final user = await _repo.signInWithProvider(provider);
      debugPrint('AUTH: Social Login Succeeded.');
      state = app.AuthState.authenticated(user);
    } catch (e) {
      if (e.toString().contains('CANCELLED') ||
          e.toString().contains('popup_closed') ||
          e.toString().contains('canceled')) {
        debugPrint('AUTH: Login cancelado pelo usuário ou popup fechado.');
        state = const app.AuthState.unauthenticated();
        return;
      }
      if (e.toString().contains('Redirecionando')) {
        debugPrint('AUTH: Redirecting to Provider...');
        final stillLoading = state.maybeMap(
          loading: (_) => true,
          orElse: () => false,
        );
        if (!stillLoading) {
          state = const app.AuthState.unauthenticated();
        }
        return;
      }
      debugPrint('AUTH: Login Error: $e');
      state = app.AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    debugPrint('AUTH: Logging out...');
    await _repo.logout();

    // Clear conversation state and cache
    _ref.read(conversationProvider.notifier).clearAll();
    await RevenueCatService.logOut();

    state = const app.AuthState.unauthenticated();
  }

  Future<void> deleteAccount() async {
    debugPrint('AUTH: Deleting user account...');
    try {
      await _repo.deleteAccount();
    } catch (e) {
      debugPrint('AUTH: Backend delete error: $e');
    }

    // Force complete local logout & cache clear
    try {
      await _repo.logout();
    } catch (_) {}

    _ref.read(conversationProvider.notifier).clearAll();
    await RevenueCatService.logOut();
    state = const app.AuthState.unauthenticated();
  }

  Future<String?> unlockSecondChamber(String passcode) async {
    return state.maybeWhen(
      authenticated: (user) async {
        try {
          final result = await _repo.verifySecondChamber(passcode);
          if (result['valid'] == true) {
            final updatedUser = UserEntity.fromJson(result['user'] as Map<String, dynamic>);
            state = app.AuthState.authenticated(updatedUser);
            return null; // Success
          } else {
            return result['reason'] as String? ?? 'Passe incorreto. Tente novamente.';
          }
        } catch (e) {
          debugPrint('AUTH: Error unlocking second chamber: $e');
          return 'Erro de conexão. Tente novamente mais tarde.';
        }
      },
      orElse: () async => 'Usuário não autenticado.',
    );
  }

  Future<void> revertToFirstChamber() async {
    state.maybeWhen(
      authenticated: (user) async {
        try {
          final updatedUser = await _repo.updateProfile(chamberLevel: 1);
          state = app.AuthState.authenticated(updatedUser);
        } catch (e) {
          debugPrint('AUTH: Error reverting to first chamber: $e');
        }
      },
      orElse: () {},
    );
  }
}
