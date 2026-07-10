import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:gnosis_chat/features/auth/data/auth_repository.dart';
import 'package:gnosis_chat/features/auth/domain/social_provider.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteSource implements AuthRepository {
  AuthRemoteSource(this._dio);
  final Dio _dio;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<UserEntity> signInWithProvider(SocialProvider provider) async {
    final oAuthProvider = provider == SocialProvider.google
        ? OAuthProvider.google
        : provider == SocialProvider.facebook
        ? OAuthProvider.facebook
        : OAuthProvider.apple;

    if (oAuthProvider == OAuthProvider.apple) {
      throw UnimplementedError(
        'Login com Apple ainda não implementado (Fase 7.3)',
      );
    }

    // This launches the browser/web-view for OAuth login
    final success = await _supabase.auth.signInWithOAuth(
      oAuthProvider,
      redirectTo: kIsWeb ? null : 'gnosis://login-callback',
    );

    if (!success) {
      throw Exception('Falha ao iniciar login com ${provider.name}');
    }

    // Note: Since this redirects out of the app, this method won't immediately
    // return the user. The app will be relaunched via deep link and the
    // auth state change listener (or splash screen) will pick up the session.
    // For now we throw an expected exception to let the UI know it's a redirect flow.
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
    await _supabase.auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Use our backend API instead of direct Supabase PostgREST
      debugPrint('AUTH_REMOTE: GET auth/me...');
      final response = await _dio.get('auth/me');
      debugPrint(
        'AUTH_REMOTE: Success. Avatar: ${response.data['avatar_url']}',
      );
      return UserEntity.fromJson(response.data);
    } catch (e) {
      debugPrint('AUTH_REMOTE: /auth/me error: $e');
      dev.log('AUTH_ERROR', error: e);
      // Fallback to basic session info if backend call fails
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
    return UserEntity.fromJson(response.data);
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
    return Map<String, dynamic>.from(response.data);
  }
}
