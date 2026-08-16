import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsPlaybackStatus { stopped, playing, paused }

class TtsState {
  const TtsState({
    this.activeMessageId,
    this.status = TtsPlaybackStatus.stopped,
    this.speechRate = kIsWeb ? 1.0 : 0.52,
    this.pitch = 0.90, // Deeper, masculine and sage-like pitch
    this.spokenOffset = 0,
  });

  final String? activeMessageId;
  final TtsPlaybackStatus status;
  final double speechRate;
  final double pitch;
  final int spokenOffset;

  bool isSpeaking(String messageId) =>
      activeMessageId == messageId && status == TtsPlaybackStatus.playing;

  bool isPaused(String messageId) =>
      activeMessageId == messageId && status == TtsPlaybackStatus.paused;

  TtsState copyWith({
    String? activeMessageId,
    TtsPlaybackStatus? status,
    double? speechRate,
    double? pitch,
    int? spokenOffset,
    bool clearActiveId = false,
  }) {
    return TtsState(
      activeMessageId:
          clearActiveId ? null : (activeMessageId ?? this.activeMessageId),
      status: status ?? this.status,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      spokenOffset: spokenOffset ?? this.spokenOffset,
    );
  }
}

class TtsNotifier extends StateNotifier<TtsState> {
  TtsNotifier() : super(const TtsState()) {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  int _currentProgressStart = 0;
  int _accumulatedOffset = 0;

  Future<void> _initTts() async {
    if (_isInitialized) return;

    try {
      await _configureVoice();

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
        );
      }

      _flutterTts.setStartHandler(() {
        state = state.copyWith(status: TtsPlaybackStatus.playing);
      });

      _flutterTts.setProgressHandler(
        (String text, int start, int end, String word) {
          _currentProgressStart = start;
        },
      );

      _flutterTts.setCompletionHandler(() {
        _accumulatedOffset = 0;
        _currentProgressStart = 0;
        state = state.copyWith(
          status: TtsPlaybackStatus.stopped,
          clearActiveId: true,
          spokenOffset: 0,
        );
      });

      _flutterTts.setCancelHandler(() {
        state = state.copyWith(
          status: TtsPlaybackStatus.stopped,
          clearActiveId: true,
          spokenOffset: 0,
        );
      });

      _flutterTts.setPauseHandler(() {
        state = state.copyWith(status: TtsPlaybackStatus.paused);
      });

      _flutterTts.setContinueHandler(() {
        state = state.copyWith(status: TtsPlaybackStatus.playing);
      });

      _flutterTts.setErrorHandler((msg) {
        final errStr = msg.toString().toLowerCase();
        // Ignore expected interruption events caused by user pausing or stopping
        if (errStr.contains('interrupted') ||
            errStr.contains('canceled') ||
            errStr.contains('cancelled')) {
          return;
        }
        debugPrint('TTS Error: $msg');
        state = state.copyWith(
          status: TtsPlaybackStatus.stopped,
          clearActiveId: true,
          spokenOffset: 0,
        );
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> _configureVoice() async {
    try {
      await _flutterTts.setLanguage('pt-BR');
      await _flutterTts.setSpeechRate(state.speechRate);
      await _flutterTts.setPitch(state.pitch);

      // Search available voices specifically prioritizing Brazilian Male voices
      final dynamic voices = await _flutterTts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        Map<dynamic, dynamic>? maleVoice;
        Map<dynamic, dynamic>? fallbackPtVoice;

        for (final v in voices) {
          if (v is Map) {
            final locale = (v['locale'] ?? '').toString().toLowerCase();
            final name = (v['name'] ?? '').toString().toLowerCase();
            final gender = (v['gender'] ?? '').toString().toLowerCase();

            final isPortuguese =
                locale.contains('pt') ||
                name.contains('portug') ||
                name.contains('brasil') ||
                name.contains('brazil');

            if (isPortuguese) {
              final isExplicitMale =
                  gender.contains('male') ||
                  gender.contains('homem') ||
                  gender.contains('masculin') ||
                  name.contains('antonio') ||
                  name.contains('daniel') ||
                  name.contains('felipe') ||
                  name.contains('ricardo') ||
                  name.contains('jorge') ||
                  name.contains('fabio') ||
                  name.contains('male') ||
                  name.contains('standard-b') ||
                  name.contains('standard-c') ||
                  name.contains('standard-d') ||
                  name.contains('wavenet-b') ||
                  name.contains('wavenet-c') ||
                  name.contains('wavenet-d');

              final isExplicitFemale =
                  gender.contains('female') ||
                  gender.contains('mulher') ||
                  name.contains('luciana') ||
                  name.contains('francisca') ||
                  name.contains('thalita') ||
                  name.contains('maria') ||
                  name.contains('helena') ||
                  name.contains('wavenet-a') ||
                  name.contains('standard-a');

              if (isExplicitMale) {
                maleVoice = v;
                break;
              } else if (!isExplicitFemale && fallbackPtVoice == null) {
                fallbackPtVoice = v;
              }
            }
          }
        }

        final selectedVoice = maleVoice ?? fallbackPtVoice;
        if (selectedVoice != null) {
          final voiceName = selectedVoice['name']?.toString() ?? '';
          final voiceLocale = selectedVoice['locale']?.toString() ?? 'pt-BR';
          await _flutterTts.setVoice({
            'name': voiceName,
            'locale': voiceLocale,
          });
        }
      }
    } catch (e) {
      debugPrint('TTS voice configuration error: $e');
    }
  }

  /// Sanitizes AI response markdown for pleasant and natural speech reading.
  static String sanitizeTextForSpeech(String rawText) {
    var text = rawText;

    // 1. Remove all in-text bracket citations like [Ele é Ele... Divino Daimon, p. 266-267] or [1] or [Fonte: ...]
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');

    // 2. Announce "Resumo: " before the summary / recap blockquote
    text = text.replaceAllMapped(
      RegExp(r'(?:^|\n)>\s*(.*?)(?=\n\n|$)', dotAll: true),
      (match) {
        final content = match.group(1)?.trim() ?? '';
        if (content.isEmpty) return '';
        if (!content.toLowerCase().startsWith('resumo') &&
            !content.toLowerCase().startsWith('síntese')) {
          return '\n\nResumo: $content\n\n';
        }
        return '\n\n$content\n\n';
      },
    );

    text = text.replaceAll(
      RegExp(r'---\s*RECAP\s*---', caseSensitive: false),
      '\n\nResumo: ',
    );
    text = text.replaceAll(
      RegExp(
        r'---\s*SUGESTOES\s*---.*',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );

    // 3. Strip markdown syntax symbols
    text = text.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\*\*|__|\*|_'), '');
    text = text.replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[\*\-•]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'```.*?```', dotAll: true), '');
    text = text.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAll(RegExp(r'\$[^\$]+\$'), '');

    // 4. Normalize spacing & cleanup orphan punctuation left by removed brackets
    text = text.replaceAllMapped(
      RegExp(r'\s+([,\.\;\:\)])'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAll(RegExp(r'\(\s*\)'), '');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Toggles playback: Speaks, Pauses, or Resumes from the exact word where paused.
  Future<void> toggleSpeak(String messageId, String rawContent) async {
    await _initTts();
    await _configureVoice();

    // 1. If currently playing this message -> PAUSE it and save progress
    if (state.isSpeaking(messageId)) {
      _accumulatedOffset += _currentProgressStart;
      _currentProgressStart = 0;
      await _flutterTts.stop();
      state = state.copyWith(
        status: TtsPlaybackStatus.paused,
        spokenOffset: _accumulatedOffset,
      );
      return;
    }

    // 2. If speaking another message -> stop previous completely
    if (state.activeMessageId != null &&
        state.activeMessageId != messageId) {
      await stop();
    }

    final speechText = sanitizeTextForSpeech(rawContent);
    if (speechText.isEmpty) return;

    // 3. If resuming from paused state on the same message
    String textToSpeak = speechText;
    if (state.isPaused(messageId) &&
        _accumulatedOffset > 0 &&
        _accumulatedOffset < speechText.length) {
      textToSpeak = speechText.substring(_accumulatedOffset);
    } else {
      _accumulatedOffset = 0;
      _currentProgressStart = 0;
    }

    state = state.copyWith(
      activeMessageId: messageId,
      status: TtsPlaybackStatus.playing,
      spokenOffset: _accumulatedOffset,
    );

    try {
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      state = state.copyWith(
        status: TtsPlaybackStatus.stopped,
        clearActiveId: true,
        spokenOffset: 0,
      );
    }
  }

  Future<void> stop() async {
    _accumulatedOffset = 0;
    _currentProgressStart = 0;
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
    state = state.copyWith(
      status: TtsPlaybackStatus.stopped,
      clearActiveId: true,
      spokenOffset: 0,
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  return TtsNotifier();
});
