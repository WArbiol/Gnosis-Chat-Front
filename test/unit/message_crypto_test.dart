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

    test('should be idempotent and not double encrypt', () {
      final encryptedOnce = MessageCrypto.encryptContent(testMessage, userId);
      final encryptedTwice = MessageCrypto.encryptContent(encryptedOnce, userId);
      expect(encryptedOnce, equals(encryptedTwice));
      expect(MessageCrypto.decryptContent(encryptedTwice, userId), equals(testMessage));
    });

    test('should handle complex multiline markdown and latex', () {
      const complexText = '''### Pistis Sophia
1. *Citação*: "Aquele que tiver ouvidos para ouvir, ouça."
   \$\$f(x) = \\int_0^\\infty e^{-x} dx\$\$
   - Emojis: 🌟🕊️🏛️
''';
      final encrypted = MessageCrypto.encryptContent(complexText, userId);
      final decrypted = MessageCrypto.decryptContent(encrypted, userId);
      expect(decrypted, equals(complexText));
    });

    test('should handle corrupted payload gracefully without throwing', () {
      const badPayload1 = 'enc:v1:corruptedPayload:invalidIV';
      const badPayload2 = 'enc:v1:onlyOnePart';
      const badPayload3 = 'enc:v1:AAA:BBB:CCC';

      expect(MessageCrypto.decryptContent(badPayload1, userId), equals(badPayload1));
      expect(MessageCrypto.decryptContent(badPayload2, userId), equals(badPayload2));
      expect(MessageCrypto.decryptContent(badPayload3, userId), equals(badPayload3));
    });
  });
}
