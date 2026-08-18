import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<AuthResponse?> signInPlatform({
  required String webClientId,
  required String iosClientId,
  required String rawNonce,
  required String hashedNonce,
}) async {
  final clientId =
      defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isNotEmpty
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
  );
}

Future<void> signOutPlatform({required String webClientId}) async {
  try {
    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
  } catch (e) {
    debugPrint('GOOGLE_AUTH: Erro ao desconectar no mobile: $e');
  }
}
