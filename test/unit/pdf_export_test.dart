import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/message_bubble.dart';

void main() {
  group('PDF Export Text Sanitization Tests', () {
    test('converts em-dash and en-dash into safe hyphens', () {
      const input = 'Gnosis — sabedoria antiga–meditação';
      final result = sanitizeTextForPdf(input);

      expect(result, contains('Gnosis - sabedoria antiga - meditação'));
    });

    test('preserves cedilla and accented Portuguese characters', () {
      const input = 'Ação, iluminação e salvação são alcançadas.';
      final result = sanitizeTextForPdf(input);

      expect(result, equals('Ação, iluminação e salvação são alcançadas.'));
    });

    test('converts LaTeX math expressions and operators into clean Unicode text', () {
      const input = r'Dada a equação $\frac{a}{b} + \sqrt{x} \times \pi \le \infty$, temos $x^2 + y_1 = 0$.';
      final result = sanitizeTextForPdf(input);

      expect(result, contains('(a / b)'));
      expect(result, contains('√(x)'));
      expect(result, contains('×'));
      expect(result, contains('π'));
      expect(result, contains('≤'));
      expect(result, contains('∞'));
      expect(result, contains('x² + y₁ = 0'));
    });

    test('converts curly typographic quotes to standard quotes', () {
      const input = '“Gnosis” é ‘conhecimento’';
      final result = sanitizeTextForPdf(input);

      expect(result, equals('"Gnosis" é \'conhecimento\''));
    });

    test('normalizes decomposed NFD Unicode combining marks to NFC (Orientação Conjugal)', () {
      const input = 'Orientac\u0327a\u0303o Conjugal';
      final result = sanitizeTextForPdf(input);

      expect(result, equals('Orientação Conjugal'));
    });
  });
}
