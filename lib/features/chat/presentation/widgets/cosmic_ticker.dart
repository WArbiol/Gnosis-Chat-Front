import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/chat/data/suggested_questions_service.dart';

class CosmicTicker extends ConsumerStatefulWidget {
  const CosmicTicker({
    super.key,
    required this.onSelectQuestion,
  });

  final ValueChanged<String>? onSelectQuestion;

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
              speed: 26.0,
              reverse: false,
              cardWidth: 260.0,
              cardHeight: 58.0,
              cardSpacing: 12.0,
              onSelectQuestion: widget.onSelectQuestion,
            ),
            const SizedBox(height: 10),
            _MarqueeTrack(
              questions: _row2Questions!,
              speed: 22.0,
              reverse: true,
              cardWidth: 260.0,
              cardHeight: 58.0,
              cardSpacing: 12.0,
              onSelectQuestion: widget.onSelectQuestion,
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
    required this.cardWidth,
    required this.cardHeight,
    required this.cardSpacing,
    required this.onSelectQuestion,
  });

  final List<SuggestedQuestion> questions;
  final double speed;
  final bool reverse;
  final double cardWidth;
  final double cardHeight;
  final double cardSpacing;
  final ValueChanged<String>? onSelectQuestion;

  @override
  State<_MarqueeTrack> createState() => _MarqueeTrackState();
}

class _MarqueeTrackState extends State<_MarqueeTrack>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final Ticker _ticker;
  late double _offset;
  Duration _lastElapsed = Duration.zero;
  bool _isPaused = false;
  bool _initialized = false;

  double get _singleListWidth =>
      widget.questions.length * (widget.cardWidth + widget.cardSpacing);

  @override
  void initState() {
    super.initState();
    final initialOffset = widget.reverse ? _singleListWidth : 0.0;
    _offset = initialOffset;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _ticker = createTicker(_onTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initialized = true;
      _ticker.start();
    });
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

    if (_isPaused || deltaMicros <= 0) return;

    final deltaSeconds = deltaMicros / 1000000.0;
    // Guard against large jumps when resuming from background
    if (deltaSeconds > 0.1) return;

    final singleWidth = _singleListWidth;
    if (singleWidth <= 0) return;

    final move = widget.speed * deltaSeconds;

    if (widget.reverse) {
      _offset -= move;
      if (_offset <= 0) {
        _offset += singleWidth;
      }
    } else {
      _offset += move;
      if (_offset >= singleWidth) {
        _offset -= singleWidth;
      }
    }

    _scrollController.jumpTo(_offset);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: widget.cardHeight,
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
            stops: [0.0, 0.06, 0.94, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: Listener(
          onPointerDown: (_) => _isPaused = true,
          onPointerUp: (_) => _isPaused = false,
          onPointerCancel: (_) => _isPaused = false,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                ..._buildCards(widget.questions),
                ..._buildCards(widget.questions),
                ..._buildCards(widget.questions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCards(List<SuggestedQuestion> list) {
    return list.map((q) {
      return Padding(
        padding: EdgeInsets.only(right: widget.cardSpacing),
        child: _TickerCard(
          question: q.question,
          width: widget.cardWidth,
          height: widget.cardHeight,
          onTap: () => widget.onSelectQuestion?.call(q.question),
        ),
      );
    }).toList();
  }
}

class _TickerCard extends StatelessWidget {
  const _TickerCard({
    required this.question,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final String question;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.accent.withValues(alpha: 0.2),
          highlightColor: AppColors.accent.withValues(alpha: 0.1),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.28),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
