import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class MessageCrypto {
  static const String _pepper = 'GnosisSecretPepper2026';
  static const String _prefix = 'enc:v1:';

  /// Derives a deterministic 256-bit AES key from userId and app pepper
  static encrypt.Key _deriveKey(String userId) {
    final bytes = utf8.encode('$userId:$_pepper');
    final hash = sha256.convert(bytes);
    return encrypt.Key.fromBase64(base64Encode(hash.bytes));
  }

  /// Encrypts plain text before persisting to Supabase
  static String encryptContent(String plainText, String? userId) {
    if (plainText.isEmpty || userId == null || userId.isEmpty) {
      return plainText;
    }

    if (plainText.startsWith(_prefix)) {
      return plainText;
    }

    try {
      final key = _deriveKey(userId);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '$_prefix${encrypted.base64}:${iv.base64}';
    } catch (_) {
      return plainText;
    }
  }

  /// Decrypts cipher text retrieved from Supabase
  static String decryptContent(String cipherText, String? userId) {
    if (cipherText.isEmpty ||
        !cipherText.startsWith(_prefix) ||
        userId == null ||
        userId.isEmpty) {
      return cipherText;
    }

    try {
      final payload = cipherText.substring(_prefix.length);
      final parts = payload.split(':');
      if (parts.length != 2) return cipherText;

      final key = _deriveKey(userId);
      final iv = encrypt.IV.fromBase64(parts[1]);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      return encrypter.decrypt64(parts[0], iv: iv);
    } catch (_) {
      return cipherText;
    }
  }
}
