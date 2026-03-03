import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _dotAnims[i],
              builder: (context, _) {
                final value = _dotAnims[i].value;
                return Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  width: 8,
                  height: 8,
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
                        blurRadius: 6 * value,
                        spreadRadius: 1 * value,
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
