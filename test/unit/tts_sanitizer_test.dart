import 'package:flutter/foundation.dart';
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

  group('TtsNotifier.selectBestVoice', () {
    final mockVoices = [
      {'name': 'en-US-Jenny', 'locale': 'en-US', 'gender': 'female'},
      {'name': 'es-ES-Alvaro', 'locale': 'es-ES', 'gender': 'male'},
      {'name': 'Luciana', 'locale': 'pt-BR', 'gender': 'female'},
      {'name': 'Felipe', 'locale': 'pt-BR', 'gender': 'male'},
      {'name': 'Siri (pt-BR)', 'locale': 'pt-BR', 'gender': 'female', 'voiceURI': 'com.apple.ttsbundle.siri_pt-BR'},
      {'name': 'pt-br-x-ptd-local', 'locale': 'pt-BR', 'gender': 'male'},
      {'name': 'pt-br-x-afs-local', 'locale': 'pt-BR', 'gender': 'female'},
    ];

    test('prioritizes Siri voice on iOS', () {
      final selected = TtsNotifier.selectBestVoice(mockVoices, TargetPlatform.iOS);
      expect(selected, isNotNull);
      expect(selected!['name'], equals('Siri (pt-BR)'));
    });

    test('falls back to male voice on iOS when Siri is missing', () {
      final voicesWithoutSiri = mockVoices.where((v) => !v['name']!.contains('Siri')).toList();
      final selected = TtsNotifier.selectBestVoice(voicesWithoutSiri, TargetPlatform.iOS);
      expect(selected, isNotNull);
      expect(selected!['name'], equals('Felipe'));
    });

    test('prioritizes pt-br-x-* voices on Android', () {
      final selected = TtsNotifier.selectBestVoice(mockVoices, TargetPlatform.android);
      expect(selected, isNotNull);
      expect(selected!['name'], equals('pt-br-x-ptd-local'));
    });

    test('falls back to male voice on Android when pt-br-x-* is missing', () {
      final voicesWithoutX = mockVoices.where((v) => !v['name']!.contains('pt-br-x')).toList();
      final selected = TtsNotifier.selectBestVoice(voicesWithoutX, TargetPlatform.android);
      expect(selected, isNotNull);
      expect(selected!['name'], equals('Felipe'));
    });

    test('prioritizes natural male voices on Desktop / macOS / Windows', () {
      final selected = TtsNotifier.selectBestVoice(mockVoices, TargetPlatform.macOS);
      expect(selected, isNotNull);
      expect(selected!['name'], equals('Felipe'));
    });

    test('returns null when voice list is empty or contains no Portuguese voices', () {
      expect(TtsNotifier.selectBestVoice([], TargetPlatform.android), isNull);
      expect(
        TtsNotifier.selectBestVoice([
          {'name': 'en-US-Jenny', 'locale': 'en-US'},
        ], TargetPlatform.iOS),
        isNull,
      );
    });
  });
}
