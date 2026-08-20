import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppleAuthService {
  AppleAuthService._();

  static String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _hashNonce(String rawNonce) {
    final bytes = utf8.encode(rawNonce);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Realiza o login com a Apple:
  /// - Na Web: Redireciona via Supabase OAuth (utilizando Services ID).
  /// - No iOS Nativo: Executa o fluxo nativo com ID Token e biometria (Face ID).
  static Future<AuthResponse?> signIn() async {
    try {
      if (kIsWeb) {
        debugPrint('APPLE_AUTH: Web OAuth flow initiated...');
        final success = await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: Uri.base.origin,
        );
        if (!success) {
          throw Exception('Falha ao iniciar autenticação com a Apple.');
        }
        throw Exception('Redirecionando...');
      }

      final rawNonce = _generateRawNonce();
      final hashedNonce = _hashNonce(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Não foi possível obter o ID Token da Apple.');
      }

      debugPrint('APPLE_AUTH: ID Token obtido. Autenticando com Supabase...');
      return await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('APPLE_AUTH: Usuário cancelou o login com Apple.');
        return null;
      }
      debugPrint('APPLE_AUTH: Erro na autorização Apple: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('APPLE_AUTH: Erro no login com Apple: $e');
      rethrow;
    }
  }
}
