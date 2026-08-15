import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:google_identity_services_web/id.dart' as gis;
import 'package:supabase_flutter/supabase_flutter.dart';

@JS('renderAndClickGoogleButton')
external void _renderAndClickGoogleButton();

Future<AuthResponse?> signInPlatform({
  required String webClientId,
  required String iosClientId,
  required String rawNonce,
  required String hashedNonce,
}) async {
  final completer = Completer<String?>();

  gis.id.initialize(gis.IdConfiguration(
    client_id: webClientId,
    auto_select: false,
    nonce: hashedNonce,
    callback: (gis.CredentialResponse response) {
      if (!completer.isCompleted) {
        completer.complete(response.credential);
      }
    },
  ));

  gis.id.prompt((gis.PromptMomentNotification notification) {
    if (notification.isNotDisplayed() ||
        notification.isSkippedMoment() ||
        notification.isDismissedMoment()) {
      debugPrint(
        'GOOGLE_AUTH: One-Tap indisponível ou fechado (${notification.getNotDisplayedReason() ?? "dismissed"}). Acionando popup nativo do Google...',
      );
      try {
        _renderAndClickGoogleButton();
      } catch (e) {
        debugPrint('GOOGLE_AUTH: Erro ao acionar popup GIS: $e');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    }
  });

  final idToken = await completer.future;
  if (idToken == null || idToken.isEmpty) {
    debugPrint('GOOGLE_AUTH: Usuário cancelou ou fechou a autenticação do Google.');
    return null;
  }

  debugPrint('GOOGLE_AUTH: ID Token obtido no Web! Autenticando com Supabase...');
  return await Supabase.instance.client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    nonce: rawNonce,
  );
}

Future<void> signOutPlatform({required String webClientId}) async {
  try {
    gis.id.disableAutoSelect();
  } catch (e) {
    debugPrint('GOOGLE_AUTH: Erro ao desabilitar auto-select no Web: $e');
  }
}
