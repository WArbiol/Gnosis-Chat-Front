import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';

class TypingIndicator extends ConsumerStatefulWidget {
  const TypingIndicator({super.key});

  @override
  ConsumerState<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends ConsumerState<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _dotCtrls;
  late final List<Animation<double>> _dotAnims;

  @override
  void initState() {
    super.initState();
    _dotCtrls = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _dotAnims = _dotCtrls.map((ctrl) {
      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    }).toList();

    // Stagger the dot animations
    for (var i = 0; i < _dotCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _dotCtrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final ctrl in _dotCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusMsg = ref.watch(agentStatusProvider);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.15),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3 glowing dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _dotAnims[i],
                  builder: (context, _) {
                    final value = _dotAnims[i].value;
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.4 + value * 0.6),
                            AppColors.accentLight.withValues(
                              alpha: 0.3 + value * 0.5,
                            ),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: value * 0.4),
                            blurRadius: 5 * value,
                            spreadRadius: 1 * value,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            if (statusMsg != null && statusMsg.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 12,
                color: AppColors.accent.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    statusMsg,
                    key: ValueKey(statusMsg),
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
