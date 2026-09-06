import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/chat/data/suggested_questions_service.dart';

class CosmicTicker extends ConsumerStatefulWidget {
  const CosmicTicker({
    super.key,
    required this.onSelectQuestion,
    this.isPaused = false,
  });

  final ValueChanged<String>? onSelectQuestion;
  final bool isPaused;

  @override
  ConsumerState<CosmicTicker> createState() => _CosmicTickerState();
}

class _CosmicTickerState extends ConsumerState<CosmicTicker> {
  List<SuggestedQuestion>? _row1Questions;
  List<SuggestedQuestion>? _row2Questions;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(suggestedQuestionsProvider);

    return questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) return const SizedBox.shrink();

        if (_row1Questions == null || _row2Questions == null) {
          final sample = questions.pickRandom(20);
          final mid = (sample.length / 2).ceil();
          _row1Questions = sample.sublist(0, mid);
          _row2Questions = sample.sublist(mid);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MarqueeTrack(
              questions: _row1Questions!,
              speed: 11.0,
              reverse: false,
              spacing: 12.0,
              onSelectQuestion: widget.onSelectQuestion,
              isPaused: widget.isPaused,
            ),
            const SizedBox(height: 12),
            _MarqueeTrack(
              questions: _row2Questions!,
              speed: 9.0,
              reverse: true,
              spacing: 12.0,
              onSelectQuestion: widget.onSelectQuestion,
              isPaused: widget.isPaused,
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _MarqueeTrack extends StatefulWidget {
  const _MarqueeTrack({
    required this.questions,
    required this.speed,
    required this.reverse,
    required this.spacing,
    required this.onSelectQuestion,
    this.isPaused = false,
  });

  final List<SuggestedQuestion> questions;
  final double speed;
  final bool reverse;
  final double spacing;
  final ValueChanged<String>? onSelectQuestion;
  final bool isPaused;

  @override
  State<_MarqueeTrack> createState() => _MarqueeTrackState();
}

class _MarqueeTrackState extends State<_MarqueeTrack>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cycleKey = GlobalKey();
  late final ScrollController _scrollController;
  late final Ticker _ticker;

  double _offset = 0.0;
  double _cycleWidth = 0.0;
  Duration _lastElapsed = Duration.zero;
  bool _isDragging = false;
  bool _isPaused = false;
  bool _initialized = false;
  DateTime _dragPauseUntil = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _ticker = createTicker(_onTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureCycle();
      if (widget.reverse && _cycleWidth > 0) {
        _offset = _cycleWidth;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_offset);
        }
      }
      _initialized = true;
      _ticker.start();
    });
  }

  void _measureCycle() {
    final box = _cycleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0) {
      _cycleWidth = box.size.width;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_initialized || !mounted || !_scrollController.hasClients) {
      _lastElapsed = elapsed;
      return;
    }

    final deltaMicros = (elapsed - _lastElapsed).inMicroseconds;
    _lastElapsed = elapsed;

    if (widget.isPaused ||
        _isDragging ||
        _isPaused ||
        DateTime.now().isBefore(_dragPauseUntil) ||
        deltaMicros <= 0) {
      return;
    }

    final deltaSeconds = deltaMicros / 1000000.0;
    if (deltaSeconds > 0.1) return; // Ignore large gaps (e.g. app in background)

    if (_cycleWidth <= 0) {
      _measureCycle();
      if (_cycleWidth <= 0) return;
    }

    final move = widget.speed * deltaSeconds;

    if (widget.reverse) {
      _offset -= move;
      while (_offset <= 0) {
        _offset += _cycleWidth;
      }
    } else {
      _offset += move;
      while (_offset >= _cycleWidth) {
        _offset -= _cycleWidth;
      }
    }

    _scrollController.jumpTo(_offset);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 42,
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.10, 0.90, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragDown: (_) {
            _isPaused = true;
          },
          onHorizontalDragStart: (_) {
            _isDragging = true;
          },
          onHorizontalDragUpdate: (details) {
            final delta = details.primaryDelta ?? 0;
            if (delta == 0) return;

            if (_cycleWidth <= 0) {
              _measureCycle();
            }
            if (_cycleWidth <= 0) return;

            _offset -= delta;
            while (_offset >= _cycleWidth) {
              _offset -= _cycleWidth;
            }
            while (_offset < 0) {
              _offset += _cycleWidth;
            }
            _scrollController.jumpTo(_offset);
          },
          onHorizontalDragEnd: (_) {
            _isDragging = false;
            _isPaused = false;
            _dragPauseUntil =
                DateTime.now().add(const Duration(milliseconds: 1200));
          },
          onHorizontalDragCancel: () {
            _isDragging = false;
            _isPaused = false;
            _dragPauseUntil =
                DateTime.now().add(const Duration(milliseconds: 1200));
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                _CycleRow(
                  key: _cycleKey,
                  questions: widget.questions,
                  spacing: widget.spacing,
                  onSelectQuestion: widget.onSelectQuestion,
                ),
                _CycleRow(
                  questions: widget.questions,
                  spacing: widget.spacing,
                  onSelectQuestion: widget.onSelectQuestion,
                ),
                _CycleRow(
                  questions: widget.questions,
                  spacing: widget.spacing,
                  onSelectQuestion: widget.onSelectQuestion,
                ),
                _CycleRow(
                  questions: widget.questions,
                  spacing: widget.spacing,
                  onSelectQuestion: widget.onSelectQuestion,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CycleRow extends StatelessWidget {
  const _CycleRow({
    super.key,
    required this.questions,
    required this.spacing,
    required this.onSelectQuestion,
  });

  final List<SuggestedQuestion> questions;
  final double spacing;
  final ValueChanged<String>? onSelectQuestion;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: questions.map((q) {
        return Padding(
          padding: EdgeInsets.only(right: spacing),
          child: _TickerPill(
            question: q.question,
            onTap: () => onSelectQuestion?.call(q.question),
          ),
        );
      }).toList(),
    );
  }
}

class _TickerPill extends StatelessWidget {
  const _TickerPill({
    required this.question,
    required this.onTap,
  });

  final String question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.accent.withValues(alpha: 0.2),
        highlightColor: AppColors.accent.withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                question,
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
