import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/auth/data/auth_remote_source.dart';
import 'package:gnosis_chat/features/auth/data/auth_repository.dart';
import 'package:gnosis_chat/features/auth/domain/auth_state.dart' as app;
import 'package:gnosis_chat/features/auth/domain/social_provider.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/conversation_provider.dart';
import 'package:gnosis_chat/services/api/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

final authProvider = StateNotifierProvider<AuthNotifier, app.AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(AuthRemoteSource(api.dio), ref);
});

class AuthNotifier extends StateNotifier<app.AuthState> {
  AuthNotifier(this._repo, this._ref) : super(const app.AuthState.initial()) {
    _initAuthListener();
  }

  final AuthRepository _repo;
  final Ref _ref;

  void _initAuthListener() {
    // 1. Initial check for existing session
    final initialSession = sb.Supabase.instance.client.auth.currentSession;
    if (initialSession != null) {
      fetchUser();
    }

    _supabaseListener = sb.Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final session = data.session;
      final event = data.event;
      debugPrint(
        '!!!!! GNOSIS AUTH EVENT: $event, Session: ${session != null}',
      );

      if (session != null) {
        // Only fetch if we are not already authenticated or if it's a significant change
        final isAuth = state.maybeMap(
          authenticated: (_) => true,
          orElse: () => false,
        );
        if (!isAuth || event == sb.AuthChangeEvent.signedIn) {
          fetchUser();
        }
      }
    });
  }

  StreamSubscription<sb.AuthState>? _supabaseListener;

  Future<void> fetchUser() async {
    debugPrint('AUTH: Fetching user profile...');
    try {
      final user = await _repo.getCurrentUser();
      if (user != null && mounted) {
        debugPrint('AUTH: Profile obtained. Avatar: ${user.avatarUrl}');
        state = app.AuthState.authenticated(user);
      } else {
        debugPrint('AUTH: Fetch skipped (user null or unmounted)');
      }
    } catch (e) {
      debugPrint('AUTH: CRITICAL ERROR in fetchUser: $e');
      if (mounted) state = app.AuthState.error(e.toString());
    }
  }

  @override
  void dispose() {
    _supabaseListener?.cancel();
    super.dispose();
  }

  Future<void> signInWithProvider(SocialProvider provider) async {
    state = const app.AuthState.loading();
    try {
      final user = await _repo.signInWithProvider(provider);
      debugPrint('AUTH: Social Login Succeeded.');
      state = app.AuthState.authenticated(user);
    } catch (e) {
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

  // Social auth only: signup and classic login with password removed.

  Future<void> logout() async {
    debugPrint('AUTH: Logging out...');
    await _repo.logout();

    // Clear conversation state and cache
    _ref.read(conversationProvider.notifier).clearAll();

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
