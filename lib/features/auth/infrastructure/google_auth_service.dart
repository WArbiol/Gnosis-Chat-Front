import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static String get webClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  static String get iosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');

  static String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }


  /// Realiza o login com Google via ID Token nativo (OpenID Connect).
  /// Retorna a `AuthResponse` do Supabase se autenticado com sucesso,
  /// ou `null` se o usuário cancelou a operação voluntariamente.
  static Future<AuthResponse?> signIn() async {
    final rawNonce = _generateRawNonce();

    final clientId = kIsWeb
        ? (webClientId.isNotEmpty ? webClientId : null)
        : (defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isNotEmpty
            ? iosClientId
            : null);

    final googleSignIn = GoogleSignIn(
      clientId: clientId,
      serverClientId: kIsWeb ? null : (webClientId.isNotEmpty ? webClientId : null),
      scopes: const ['email', 'profile', 'openid'],
    );

    // Inicia o fluxo nativo (Bottom Sheet no Mobile / One-Tap ou Popup no Web)
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('GOOGLE_AUTH: Usuário cancelou o login.');
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Não foi possível obter o ID Token do Google. Verifique a configuração do Client ID.',
      );
    }

    debugPrint('GOOGLE_AUTH: ID Token obtido. Autenticando com Supabase...');

    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
      nonce: rawNonce,
    );

    return response;
  }

  /// Desconecta a conta do Google SDK localmente
  static Future<void> signOut() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? (webClientId.isNotEmpty ? webClientId : null) : null,
        serverClientId: kIsWeb ? null : (webClientId.isNotEmpty ? webClientId : null),
      );
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('GOOGLE_AUTH: Erro ao desconectar Google SignIn: $e');
    }
  }
}
