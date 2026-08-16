import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/services/audio/tts_service.dart';

void main() {
  group('TtsNotifier.sanitizeTextForSpeech', () {
    test('removes in-text citations inside brackets', () {
      const raw =
          'A Mãe Divina é a raiz inefável do amor [Ele é Ele... Divino Daimon, p. 266-267]. Na Gnosis [1], Ela é reverenciada.';
      final result = TtsNotifier.sanitizeTextForSpeech(raw);

      expect(result, contains('A Mãe Divina é a raiz inefável do amor. Na Gnosis, Ela é reverenciada.'));
      expect(result, isNot(contains('[Ele é Ele... Divino Daimon, p. 266-267]')));
      expect(result, isNot(contains('[1]')));
    });

    test('adds Resumo prefix before recap blockquote', () {
      const raw =
          'A sabedoria gnóstica liberta a consciência.\n\n> Sintetizando a jornada de aprendizado, compreendemos o papel da Mãe Divina.';
      final result = TtsNotifier.sanitizeTextForSpeech(raw);

      expect(result, contains('Resumo: Sintetizando a jornada de aprendizado, compreendemos o papel da Mãe Divina.'));
    });

    test('removes markdown formatting tokens', () {
      const raw =
          '### Natureza e Aspectos\n\n1. **Deus-Mãe**: A força de *Devi Kundalini*.\n- Item A\n- Item B';
      final result = TtsNotifier.sanitizeTextForSpeech(raw);

      expect(result, isNot(contains('###')));
      expect(result, isNot(contains('**')));
      expect(result, isNot(contains('*Devi Kundalini*')));
      expect(result, contains('Natureza e Aspectos'));
      expect(result, contains('1. Deus-Mãe: A força de Devi Kundalini.'));
      expect(result, contains('Item A'));
      expect(result, contains('Item B'));
    });
  });

  group('TtsNotifier.splitIntoSentences', () {
    test('splits paragraphs into distinct spoken sentences', () {
      const text =
          'Na tradição da Gnosis, a Mãe Divina não é uma entidade externa. Ela é a força primordial do Ser! Como despertar esse poder? Pratique a auto-observação.';
      final sentences = TtsNotifier.splitIntoSentences(text);

      expect(sentences.length, equals(4));
      expect(sentences[0], equals('Na tradição da Gnosis, a Mãe Divina não é uma entidade externa.'));
      expect(sentences[1], equals('Ela é a força primordial do Ser!'));
      expect(sentences[2], equals('Como despertar esse poder?'));
      expect(sentences[3], equals('Pratique a auto-observação.'));
    });
  });
}
