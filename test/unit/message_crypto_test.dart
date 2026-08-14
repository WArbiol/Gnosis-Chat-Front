import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/core/utils/message_crypto.dart';

void main() {
  group('MessageCrypto', () {
    const userId = 'a1b2c3d4-e5f6-7890-1234-567890abcdef';
    const testMessage = 'O Divino Daimon representa a parte superior do Ser íntimo. ✨📖';

    test('should encrypt and decrypt message correctly', () {
      final encrypted = MessageCrypto.encryptContent(testMessage, userId);
      expect(encrypted.startsWith('enc:v1:'), isTrue);
      expect(encrypted, isNot(equals(testMessage)));

      final decrypted = MessageCrypto.decryptContent(encrypted, userId);
      expect(decrypted, equals(testMessage));
    });

    test('should return legacy plaintext untouched', () {
      const legacyMessage = 'Mensagem antiga sem criptografia';
      final decrypted = MessageCrypto.decryptContent(legacyMessage, userId);
      expect(decrypted, equals(legacyMessage));
    });

    test('should safely handle different user IDs', () {
      const otherUserId = 'other-user-9999-8888';
      final encrypted = MessageCrypto.encryptContent(testMessage, userId);
      final decrypted = MessageCrypto.decryptContent(encrypted, otherUserId);
      expect(decrypted, isNot(equals(testMessage)));
    });

    test('should handle empty or null values safely', () {
      expect(MessageCrypto.encryptContent('', userId), equals(''));
      expect(MessageCrypto.encryptContent(testMessage, null), equals(testMessage));
      expect(MessageCrypto.decryptContent('', userId), equals(''));
      expect(MessageCrypto.decryptContent(testMessage, null), equals(testMessage));
    });
  });
}
