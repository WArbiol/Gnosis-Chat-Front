import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';
import 'package:gnosis_chat/features/subscription/presentation/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient blobs — one blue, one gold for warmth
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          fixedSize: const Size(48, 48),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Escolha Seu Caminho',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Plans
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: PlanType.values.map((type) {
                      return _PlanCard(
                        plan: type.entity,
                        tint: _planTint(type),
                        isLoading: planState.isLoading,
                        onSelect: () => ref
                            .read(subscriptionProvider.notifier)
                            .checkout(type),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Each plan gets a unique color identity — subtle, not aggressive.
  static Color _planTint(PlanType type) => switch (type) {
    PlanType.free => AppColors.onSurfaceVariant,
    PlanType.basic => AppColors.primary,
    PlanType.premium => AppColors.accent,
  };
}

// ---------------------------------------------------------------------------
// Plan card — glassmorphism with per-plan color tint
// ---------------------------------------------------------------------------
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.tint,
    required this.isLoading,
    required this.onSelect,
  });

  final PlanEntity plan;
  final Color tint;
  final bool isLoading;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: tint.withValues(alpha: 0.04),
              border: Border.all(color: tint.withValues(alpha: 0.12), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.displayName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface.withValues(
                                    alpha: 0.95,
                                  ),
                                  letterSpacing: 0.3,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.priceMonthly == 0
                                ? 'Grátis'
                                : 'R\$ ${plan.priceMonthly.toStringAsFixed(2)}/mês',
                            style: TextStyle(
                              color: tint.withValues(alpha: 0.85),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icon badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: tint.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        _planIcon(plan.type),
                        size: 22,
                        color: tint.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                const SizedBox(height: 14),

                // Features
                _FeatureItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: '${plan.questionLimit} perguntas/mês',
                  tint: tint,
                ),
                if (plan.interestLimit > 0) ...[
                  const SizedBox(height: 8),
                  _FeatureItem(
                    icon: Icons.psychology_outlined,
                    text: '${plan.interestLimit} memórias de interesse',
                    tint: tint,
                  ),
                ],

                const SizedBox(height: 20),

                // CTA — outlined, gentle, not aggressive
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            onSelect();
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tint,
                      side: BorderSide(color: tint.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tint,
                            ),
                          )
                        : Text(
                            'Selecionar ${plan.displayName}',
                            style: TextStyle(
                              color: tint.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
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

  static IconData _planIcon(PlanType type) => switch (type) {
    PlanType.free => Icons.explore_outlined,
    PlanType.basic => Icons.auto_awesome_outlined,
    PlanType.premium => Icons.workspace_premium_rounded,
  };
}

// ---------------------------------------------------------------------------
// Feature item row
// ---------------------------------------------------------------------------
class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.tint,
  });

  final IconData icon;
  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: tint.withValues(alpha: 0.45)),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: AppColors.onSurface.withValues(alpha: 0.65),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
