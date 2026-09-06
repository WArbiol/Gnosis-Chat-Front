import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/cosmic_ticker.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.glowAnim,
    this.onSelectQuestion,
    this.isInputFocused = false,
  });

  final Animation<double> glowAnim;
  final ValueChanged<String>? onSelectQuestion;
  final bool isInputFocused;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.isInputFocused ? 0.0 : 1.0,
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant EmptyState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInputFocused != oldWidget.isInputFocused) {
      if (widget.isInputFocused) {
        _fadeCtrl.reverse();
      } else {
        _fadeCtrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animated glow
            AnimatedBuilder(
              animation: widget.glowAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(
                          alpha: widget.glowAnim.value * 0.4,
                        ),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: widget.glowAnim.value * 0.2,
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
                'Pergunte à Gnosis...',
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

            const SizedBox(height: 28),

            // Cosmic Ticker Slider with GPU-accelerated FadeTransition and RepaintBoundary
            RepaintBoundary(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: IgnorePointer(
                  ignoring: widget.isInputFocused,
                  child: CosmicTicker(
                    onSelectQuestion: widget.onSelectQuestion,
                    isPaused: widget.isInputFocused,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
