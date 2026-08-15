import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_identity_services_web/id.dart' as gis;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Realiza o login com Google via ID Token nativo (OpenID Connect).
  /// Retorna a `AuthResponse` do Supabase se autenticado com sucesso,
  /// ou `null` se o usuário cancelou a operação voluntariamente.
  static Future<AuthResponse?> signIn() async {
    final rawNonce = _generateRawNonce();

    if (kIsWeb) {
      // No Web, utiliza Google Identity Services (One-Tap / Prompt nativo)
      // para obter diretamente o ID Token na origem gnosischat.com (ZERO redirect para supabase.co)
      final completer = Completer<String?>();

      gis.id.initialize(gis.IdConfiguration(
        client_id: webClientId,
        auto_select: false,
        nonce: rawNonce,
        callback: (gis.CredentialResponse response) {
          if (!completer.isCompleted) {
            completer.complete(response.credential);
          }
        },
      ));

      gis.id.prompt((gis.PromptMomentNotification notification) {
        if (notification.isDismissedMoment() || notification.isSkippedMoment()) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      });

      final idToken = await completer.future;
      if (idToken == null || idToken.isEmpty) {
        debugPrint('GOOGLE_AUTH: Usuário fechou o prompt One-Tap ou cancelou.');
        return null;
      }

      debugPrint('GOOGLE_AUTH: ID Token (GIS) obtido no Web! Autenticando com Supabase...');
      return await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        nonce: rawNonce,
      );
    }

    // Fluxo Mobile (Android / iOS) — 100% Nativo via ID Token (Play Services / Apple Sheet)
    final clientId = defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isNotEmpty
        ? iosClientId
        : null;

    final googleSignIn = GoogleSignIn(
      clientId: clientId,
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
      scopes: const ['email', 'profile', 'openid'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('GOOGLE_AUTH: Usuário cancelou o login no mobile.');
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Não foi possível obter o ID Token do Google no dispositivo móvel.',
      );
    }

    debugPrint('GOOGLE_AUTH: ID Token obtido no mobile. Autenticando com Supabase...');
    return await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
      nonce: rawNonce,
    );
  }

  /// Desconecta a conta do Google SDK localmente
  static Future<void> signOut() async {
    try {
      if (kIsWeb) {
        gis.id.disableAutoSelect();
      } else {
        final googleSignIn = GoogleSignIn(
          serverClientId: webClientId.isNotEmpty ? webClientId : null,
        );
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      }
    } catch (e) {
      debugPrint('GOOGLE_AUTH: Erro ao desconectar Google SignIn: $e');
    }
  }
}
