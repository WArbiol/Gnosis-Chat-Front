import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:gnosis_chat/features/auth/data/auth_repository.dart';
import 'package:gnosis_chat/features/auth/data/user_cache.dart';
import 'package:gnosis_chat/features/auth/domain/social_provider.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';
import 'package:gnosis_chat/features/auth/infrastructure/apple_auth_service.dart';
import 'package:gnosis_chat/features/auth/infrastructure/google_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteSource implements AuthRepository {
  AuthRemoteSource(this._dio, [UserCache? userCache]) : _userCache = userCache ?? UserCache();
  final Dio _dio;
  final UserCache _userCache;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<UserEntity> signInWithProvider(SocialProvider provider) async {
    if (provider == SocialProvider.google) {
      final response = await GoogleAuthService.signIn();
      if (response == null) {
        throw Exception('CANCELLED');
      }

      final currentUser = await getCurrentUser();
      if (currentUser != null) return currentUser;

      final sbUser = response.user;
      if (sbUser == null) {
        throw Exception('CANCELLED');
      }

      return UserEntity(
        id: sbUser.id,
        email: sbUser.email ?? '',
        avatarUrl: sbUser.userMetadata?['avatar_url'] as String?,
      );
    }

    if (provider == SocialProvider.apple) {
      final response = await AppleAuthService.signIn();
      if (response == null) {
        throw Exception('CANCELLED');
      }

      final currentUser = await getCurrentUser();
      if (currentUser != null) return currentUser;

      final sbUser = response.user;
      if (sbUser == null) {
        throw Exception('CANCELLED');
      }

      return UserEntity(
        id: sbUser.id,
        email: sbUser.email ?? '',
        avatarUrl: sbUser.userMetadata?['avatar_url'] as String?,
      );
    }

    final oAuthProvider = provider == SocialProvider.facebook
        ? OAuthProvider.facebook
        : OAuthProvider.apple;

    // This launches the browser/web-view for OAuth login
    final success = await _supabase.auth.signInWithOAuth(
      oAuthProvider,
      redirectTo: kIsWeb ? Uri.base.origin : 'gnosis://login-callback',
    );

    if (!success) {
      throw Exception('Falha ao iniciar login com ${provider.name}');
    }

    throw Exception('Redirecionando...');
  }

  @override
  Future<UserEntity> signup({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Social auth only for now');
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Social auth only for now');
  }

  @override
  Future<void> logout() async {
    await GoogleAuthService.signOut();
    await _supabase.auth.signOut();
    await _userCache.clear();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      debugPrint('AUTH_REMOTE: GET auth/me...');
      final response = await _dio.get('auth/me');
      debugPrint(
        'AUTH_REMOTE: Success. Avatar: ${response.data['avatar_url']}',
      );
      final fetchedUser = UserEntity.fromJson(response.data);
      // Persist to local cache immediately
      await _userCache.saveUser(fetchedUser);
      return fetchedUser;
    } catch (e) {
      debugPrint('AUTH_REMOTE: /auth/me error: $e');
      dev.log('AUTH_ERROR', error: e);

      // 1. Return cached user profile if available to prevent regression to Free tier
      final cachedUser = _userCache.loadUser();
      if (cachedUser != null && cachedUser.id == user.id) {
        debugPrint('AUTH_REMOTE: Returning cached user with plan: ${cachedUser.plan}');
        return cachedUser;
      }

      // 2. Fallback to basic session info only if no cache exists
      final meta = user.userMetadata;
      debugPrint('AUTH_REMOTE: Fallback to metadata: ${meta?['avatar_url']}');
      return UserEntity(
        id: user.id,
        email: user.email ?? '',
        avatarUrl: meta?['avatar_url'] ?? meta?['picture'],
      );
    }
  }

  @override
  Future<UserEntity> updateProfile({int? chamberLevel}) async {
    final response = await _dio.patch(
      'auth/me',
      data: {
        'chamber_level': chamberLevel,
      }..removeWhere((k, v) => v == null),
    );
    final updatedUser = UserEntity.fromJson(response.data);
    await _userCache.saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<Map<String, dynamic>> verifySecondChamber(String passcode) async {
    final response = await _dio.post(
      'auth/second-chamber/verify',
      data: {
        'passcode': passcode,
      },
    );
    // Returns {"valid": true, "reason": "...", "user": ...}
    final result = Map<String, dynamic>.from(response.data);
    if (result['valid'] == true && result['user'] != null) {
      final updatedUser = UserEntity.fromJson(result['user'] as Map<String, dynamic>);
      await _userCache.saveUser(updatedUser);
    }
    return result;
  }

  @override
  Future<void> deleteAccount() async {
    debugPrint('AUTH_REMOTE: POST auth/delete-account...');
    await _dio.post('auth/delete-account');
    await _userCache.clear();
    debugPrint('AUTH_REMOTE: Account deleted successfully.');
  }
}
