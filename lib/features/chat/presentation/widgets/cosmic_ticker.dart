import 'package:flutter/material.dart';
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

class _CosmicTickerState extends ConsumerState<CosmicTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 65),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _animCtrl.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _animCtrl.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(suggestedQuestionsProvider);

    return questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) return const SizedBox.shrink();

        // Divide perguntas para as 2 faixas
        final half = questions.length ~/ 2;
        final row1 = questions.sublist(0, half);
        final row2 = questions.sublist(half);

        return GestureDetector(
          onTapDown: (_) => _pause(),
          onTapUp: (_) => _resume(),
          onTapCancel: _resume,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMarqueeRow(
                questions: row1,
                reverseDirection: false,
              ),
              const SizedBox(height: 12),
              _buildMarqueeRow(
                questions: row2,
                reverseDirection: true,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMarqueeRow({
    required List<SuggestedQuestion> questions,
    required bool reverseDirection,
  }) {
    // Duplica lista para efeito contínuo sem saltos
    final displayList = [...questions.take(15), ...questions.take(15)];

    return SizedBox(
      height: 44,
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
            stops: [0.0, 0.08, 0.92, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, child) {
            final value = _animCtrl.value;
            // Deslocamento contínuo
            final offsetPct = reverseDirection ? (value - 1.0) : -value;

            return FractionalTranslation(
              translation: Offset(offsetPct * 0.5, 0),
              child: child,
            );
          },
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final q = displayList[index];
              return _TickerCard(
                question: q.question,
                onTap: () => widget.onSelectQuestion?.call(q.question),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TickerCard extends StatelessWidget {
  const _TickerCard({
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
        borderRadius: BorderRadius.circular(22),
        splashColor: AppColors.accent.withValues(alpha: 0.2),
        highlightColor: AppColors.accent.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
