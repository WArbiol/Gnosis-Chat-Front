import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.glowAnim});

  final Animation<double> glowAnim;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animated glow
            AnimatedBuilder(
              animation: glowAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(
                          alpha: glowAnim.value * 0.4,
                        ),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: glowAnim.value * 0.2,
                        ),
                        blurRadius: 80,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
            ),

            const SizedBox(height: 24),

            // Welcome text with gold gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Pergunte ao Gnosis...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Conhecimento sagrado ao seu alcance',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
