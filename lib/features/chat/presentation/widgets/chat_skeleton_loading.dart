import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';

class ChatSkeletonLoading extends StatefulWidget {
  const ChatSkeletonLoading({super.key});

  @override
  State<ChatSkeletonLoading> createState() => _ChatSkeletonLoadingState();
}

class _ChatSkeletonLoadingState extends State<ChatSkeletonLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 0.15,
      end: 0.45,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final opacity = _pulseAnim.value;
        return ListView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 100,
            bottom: 120,
          ),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // User skeleton bubble (Right aligned)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 220,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: opacity),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // AI skeleton bubble 1 (Left aligned)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.sizeOf(context).width * 0.75,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: opacity * 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.onSurface.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: MediaQuery.sizeOf(context).width * 0.55,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.onSurface.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: MediaQuery.sizeOf(context).width * 0.35,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.onSurface.withValues(alpha: opacity * 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User skeleton bubble 2
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 180,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: opacity),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // AI skeleton bubble 2
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.sizeOf(context).width * 0.6,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: opacity * 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.onSurface.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.onSurface.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
