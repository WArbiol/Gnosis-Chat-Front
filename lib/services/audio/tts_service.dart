import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gnosis_chat/services/audio/web_tts.dart';

enum TtsPlaybackStatus { stopped, playing, paused }

class TtsState {
  const TtsState({
    this.activeMessageId,
    this.status = TtsPlaybackStatus.stopped,
    this.speechRate = kIsWeb ? 1.0 : 0.52,
    this.pitch = 0.88, // Deeper masculine and calm tone
    this.currentSentenceIndex = 0,
    this.totalSentences = 0,
  });

  final String? activeMessageId;
  final TtsPlaybackStatus status;
  final double speechRate;
  final double pitch;
  final int currentSentenceIndex;
  final int totalSentences;

  bool isSpeaking(String messageId) =>
      activeMessageId == messageId && status == TtsPlaybackStatus.playing;

  bool isPaused(String messageId) =>
      activeMessageId == messageId && status == TtsPlaybackStatus.paused;

  TtsState copyWith({
    String? activeMessageId,
    TtsPlaybackStatus? status,
    double? speechRate,
    double? pitch,
    int? currentSentenceIndex,
    int? totalSentences,
    bool clearActiveId = false,
  }) {
    return TtsState(
      activeMessageId:
          clearActiveId ? null : (activeMessageId ?? this.activeMessageId),
      status: status ?? this.status,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      currentSentenceIndex:
          currentSentenceIndex ?? this.currentSentenceIndex,
      totalSentences: totalSentences ?? this.totalSentences,
    );
  }
}

class TtsNotifier extends StateNotifier<TtsState> {
  TtsNotifier() : super(const TtsState()) {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  List<String> _sentenceQueue = [];
  int _currentIndex = 0;
  bool _isManuallyPaused = false;
  int _playSessionId = 0;

  Future<void> _initTts() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      try {
        setJsOnGnosisTtsComplete(() {
          if (!_isManuallyPaused) {
            _onSentenceComplete();
          }
        });
      } catch (e) {
        debugPrint('Web TTS setup error: $e');
      }
      _isInitialized = true;
      return;
    }

    try {
      await _configureVoice();

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
        );
      }

      _flutterTts.setCompletionHandler(() {
        if (_isManuallyPaused) return;
        _onSentenceComplete();
      });

      _flutterTts.setCancelHandler(() {
        if (_isManuallyPaused) return;
        stop();
      });

      _flutterTts.setErrorHandler((msg) {
        final errStr = msg.toString().toLowerCase();
        if (errStr.contains('interrupted') ||
            errStr.contains('canceled') ||
            errStr.contains('cancelled')) {
          return;
        }
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  void _onSentenceComplete() {
    if (_isManuallyPaused || state.status != TtsPlaybackStatus.playing) return;

    final nextIndex = _currentIndex + 1;
    if (nextIndex < _sentenceQueue.length) {
      _currentIndex = nextIndex;
      state = state.copyWith(currentSentenceIndex: _currentIndex);
      _speakCurrentSentence(_playSessionId);
    } else {
      // Completed full message
      _isManuallyPaused = true;
      _currentIndex = 0;
      _sentenceQueue = [];
      state = state.copyWith(
        status: TtsPlaybackStatus.stopped,
        clearActiveId: true,
        currentSentenceIndex: 0,
        totalSentences: 0,
      );
    }
  }

  Future<void> _speakCurrentSentence(int sessionId) async {
    if (_isManuallyPaused || sessionId != _playSessionId) return;
    if (_currentIndex >= _sentenceQueue.length) {
      stop();
      return;
    }

    final sentence = _sentenceQueue[_currentIndex];

    if (kIsWeb) {
      try {
        jsGnosisSpeak(
          sentence,
          state.pitch,
          state.speechRate,
        );
      } catch (e) {
        debugPrint('Web TTS speak error: $e');
      }
      return;
    }

    try {
      await _flutterTts.speak(sentence);
    } catch (e) {
      debugPrint('Native TTS speak error: $e');
    }
  }

  Future<void> _configureVoice() async {
    if (kIsWeb) return;

    try {
      await _flutterTts.setLanguage('pt-BR');
      await _flutterTts.setSpeechRate(state.speechRate);
      await _flutterTts.setPitch(state.pitch);

      final dynamic voices = await _flutterTts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        Map<dynamic, dynamic>? bestMaleVoice;
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

              if (isExplicitMale) {
                bestMaleVoice = v;
                break;
              } else {
                fallbackPtVoice ??= v;
              }
            }
          }
        }

        final selectedVoice = bestMaleVoice ?? fallbackPtVoice;
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

  /// Splits clean text into natural sentences for deterministic pause/resume.
  static List<String> splitIntoSentences(String text) {
    if (text.isEmpty) return [];
    final rawChunks = text.split(RegExp(r'(?<=[.!?;\n])\s+'));
    final List<String> result = [];
    for (final chunk in rawChunks) {
      final trimmed = chunk.trim();
      if (trimmed.isNotEmpty) {
        result.add(trimmed);
      }
    }
    return result.isEmpty ? [text] : result;
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

  /// Toggles playback: Speaks, Pauses, or Resumes from the current sentence.
  Future<void> toggleSpeak(String messageId, String rawContent) async {
    await _initTts();

    // 1. If currently playing this message -> PAUSE it
    if (state.activeMessageId == messageId &&
        state.status == TtsPlaybackStatus.playing) {
      _isManuallyPaused = true;
      _playSessionId++;

      if (kIsWeb) {
        try {
          jsGnosisStopTts();
        } catch (_) {}
      } else {
        try {
          await _flutterTts.stop();
        } catch (_) {}
      }

      state = state.copyWith(
        activeMessageId: messageId,
        status: TtsPlaybackStatus.paused,
        currentSentenceIndex: _currentIndex,
      );
      return;
    }

    // 2. If paused or stopped on this SAME message and has remaining sentences -> RESUME
    if (state.activeMessageId == messageId &&
        _sentenceQueue.isNotEmpty &&
        _currentIndex < _sentenceQueue.length) {
      _isManuallyPaused = false;
      _playSessionId++;
      state = state.copyWith(
        activeMessageId: messageId,
        status: TtsPlaybackStatus.playing,
        currentSentenceIndex: _currentIndex,
      );
      await _speakCurrentSentence(_playSessionId);
      return;
    }

    // 3. Brand new message or replay from start:
    _isManuallyPaused = true;
    _playSessionId++;

    if (kIsWeb) {
      try {
        jsGnosisStopTts();
      } catch (_) {}
    } else {
      try {
        await _flutterTts.stop();
      } catch (_) {}
    }

    final speechText = sanitizeTextForSpeech(rawContent);
    if (speechText.isEmpty) return;

    _sentenceQueue = splitIntoSentences(speechText);
    if (_sentenceQueue.isEmpty) return;

    _currentIndex = 0;
    _isManuallyPaused = false;

    await _configureVoice();

    state = state.copyWith(
      activeMessageId: messageId,
      status: TtsPlaybackStatus.playing,
      currentSentenceIndex: 0,
      totalSentences: _sentenceQueue.length,
    );

    await _speakCurrentSentence(_playSessionId);
  }

  Future<void> stop() async {
    _isManuallyPaused = true;
    _playSessionId++;
    _currentIndex = 0;
    _sentenceQueue = [];

    if (kIsWeb) {
      try {
        jsGnosisStopTts();
      } catch (_) {}
    } else {
      try {
        await _flutterTts.stop();
      } catch (_) {}
    }

    state = state.copyWith(
      status: TtsPlaybackStatus.stopped,
      clearActiveId: true,
      currentSentenceIndex: 0,
      totalSentences: 0,
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  return TtsNotifier();
});
