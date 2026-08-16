import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsPlaybackStatus { stopped, playing, paused }

class TtsState {
  const TtsState({
    this.activeMessageId,
    this.status = TtsPlaybackStatus.stopped,
    this.speechRate = 0.5, // 0.5 is natural reading speed for pt-BR in flutter_tts
    this.pitch = 1.0,
  });

  final String? activeMessageId;
  final TtsPlaybackStatus status;
  final double speechRate;
  final double pitch;

  bool isSpeaking(String messageId) =>
      activeMessageId == messageId && status == TtsPlaybackStatus.playing;

  TtsState copyWith({
    String? activeMessageId,
    TtsPlaybackStatus? status,
    double? speechRate,
    double? pitch,
    bool clearActiveId = false,
  }) {
    return TtsState(
      activeMessageId: clearActiveId ? null : (activeMessageId ?? this.activeMessageId),
      status: status ?? this.status,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
    );
  }
}

class TtsNotifier extends StateNotifier<TtsState> {
  TtsNotifier() : super(const TtsState()) {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _initTts() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('pt-BR');
      await _flutterTts.setSpeechRate(state.speechRate);
      await _flutterTts.setPitch(state.pitch);

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

      _flutterTts.setCompletionHandler(() {
        state = state.copyWith(
          status: TtsPlaybackStatus.stopped,
          clearActiveId: true,
        );
      });

      _flutterTts.setCancelHandler(() {
        state = state.copyWith(
          status: TtsPlaybackStatus.stopped,
          clearActiveId: true,
        );
      });

      _flutterTts.setPauseHandler(() {
        state = state.copyWith(status: TtsPlaybackStatus.paused);
      });

      _flutterTts.setContinueHandler(() {
        state = state.copyWith(status: TtsPlaybackStatus.playing);
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        state = state.copyWith(
          status: TtsPlaybackStatus.stopped,
          clearActiveId: true,
        );
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  /// Sanitizes AI response markdown for pleasant and natural speech reading.
  static String sanitizeTextForSpeech(String rawText) {
    var text = rawText;

    // 1. Remove all in-text bracket citations like [Ele é Ele... Divino Daimon, p. 266-267] or [1] or [Fonte: ...]
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');

    // 2. Announce "Resumo: " before the summary / recap blockquote
    // Checks for markdown blockquote > or ---RECAP--- or ### Resumo
    text = text.replaceAllMapped(
      RegExp(r'(?:^|\n)>\s*(.*?)(?=\n\n|$)', dotAll: true),
      (match) {
        final content = match.group(1)?.trim() ?? '';
        if (content.isEmpty) return '';
        // If content doesn't already start with "Resumo" or "Síntese", announce it
        if (!content.toLowerCase().startsWith('resumo') &&
            !content.toLowerCase().startsWith('síntese')) {
          return '\n\nResumo: $content\n\n';
        }
        return '\n\n$content\n\n';
      },
    );

    text = text.replaceAll(RegExp(r'---\s*RECAP\s*---', caseSensitive: false), '\n\nResumo: ');
    text = text.replaceAll(RegExp(r'---\s*SUGESTOES\s*---.*', caseSensitive: false, dotAll: true), '');

    // 3. Strip markdown syntax symbols
    // Headers
    text = text.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    // Bold / Italics
    text = text.replaceAll(RegExp(r'\*\*|__|\*|_'), '');
    // Horizontal lines
    text = text.replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), '');
    // Bullets (replace with slight pause / comma)
    text = text.replaceAll(RegExp(r'^\s*[\*\-•]\s+', multiLine: true), '');
    // Code blocks & inline code
    text = text.replaceAll(RegExp(r'```.*?```', dotAll: true), '');
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '');
    // Math/LaTeX $formula$
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

  /// Toggles playback for a specific message.
  Future<void> toggleSpeak(String messageId, String rawContent) async {
    await _initTts();

    // If currently speaking this message -> stop it
    if (state.isSpeaking(messageId)) {
      await stop();
      return;
    }

    // If speaking another message -> stop previous first
    if (state.status == TtsPlaybackStatus.playing) {
      await stop();
    }

    final speechText = sanitizeTextForSpeech(rawContent);
    if (speechText.isEmpty) return;

    state = state.copyWith(
      activeMessageId: messageId,
      status: TtsPlaybackStatus.playing,
    );

    try {
      await _flutterTts.speak(speechText);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      state = state.copyWith(
        status: TtsPlaybackStatus.stopped,
        clearActiveId: true,
      );
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
    state = state.copyWith(
      status: TtsPlaybackStatus.stopped,
      clearActiveId: true,
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
