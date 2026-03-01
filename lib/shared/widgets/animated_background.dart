import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';

/// Animated gradient blobs that create the ambient light source for glass effects.
///
/// Shared between login and chat screens.
/// [intensity] controls opacity multiplier (1.0 = full, 0.5 = subtle).
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({
    super.key,
    required this.animation,
    this.intensity = 1.0,
  });

  final Animation<double> animation;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          children: [
            // Gold blob — upper left
            Positioned(
              top: screen.height * 0.30,
              left: -70,
              child: _Blob(
                size: 200,
                color: AppColors.flameLight,
                alpha: animation.value * 0.35 * intensity,
              ),
            ),
            // Blue blob — lower right
            Positioned(
              top: screen.height * 0.50,
              right: -100,
              child: _Blob(
                size: 240,
                color: AppColors.primary,
                alpha: animation.value * 0.3 * intensity,
              ),
            ),
            // Subtle gold — bottom left
            Positioned(
              bottom: -screen.height * 0.02,
              left: -screen.width * 0.05,
              child: _Blob(
                size: 180,
                color: AppColors.accent,
                alpha: animation.value * 0.2 * intensity,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color, required this.alpha});

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
