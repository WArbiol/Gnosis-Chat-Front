import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'google_auth_stub.dart'
    if (dart.library.js_interop) 'google_auth_web.dart'
    if (dart.library.html) 'google_auth_web.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static String get webClientId {
    final fromEnv = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    const fromDef = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
    if (fromDef.isNotEmpty) return fromDef;
    return '971574732695-ndhmbf15ocp31buk94kgf5jo0jj3j0rq.apps.googleusercontent.com';
  }

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

  static String _hashNonce(String rawNonce) {
    final bytes = utf8.encode(rawNonce);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Realiza o login com Google via ID Token nativo (OpenID Connect).
  /// Retorna a `AuthResponse` do Supabase se autenticado com sucesso,
  /// ou `null` se o usuário cancelou a operação voluntariamente.
  static Future<AuthResponse?> signIn() async {
    final rawNonce = _generateRawNonce();
    final hashedNonce = _hashNonce(rawNonce);

    return await signInPlatform(
      webClientId: webClientId,
      iosClientId: iosClientId,
      rawNonce: rawNonce,
      hashedNonce: hashedNonce,
    );
  }

  /// Desconecta a conta do Google SDK localmente
  static Future<void> signOut() async {
    await signOutPlatform(webClientId: webClientId);
  }
}
