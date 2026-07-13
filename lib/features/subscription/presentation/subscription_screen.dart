import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';
import 'package:gnosis_chat/features/subscription/presentation/subscription_provider.dart';
import 'package:gnosis_chat/features/subscription/presentation/widgets/subscription_success_dialog.dart';
import 'package:gnosis_chat/shared/providers/user_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with WidgetsBindingObserver {
  PlanType? _loadingPlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh user profile when returning from Stripe checkout browser
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(authProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(subscriptionProvider);
    final currentUser = ref.watch(userProvider);
    final currentPlan = currentUser?.plan ?? 'free';

    // Show snackbar on error
    ref.listen(subscriptionProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.flame,
            ),
          );
        },
      );
    });

    // Show congratulatory dialog on subscription upgrades
    ref.listen(userProvider, (prev, next) {
      if (next == null) return;
      final oldPlan = prev?.plan;
      final newPlan = next.plan;

      // Only trigger if the plan changed and the new plan is basic or premium
      if (oldPlan != null &&
          oldPlan != newPlan &&
          (newPlan == 'basic' || newPlan == 'premium')) {
        SubscriptionSuccessDialog.show(context, newPlan);
      }
    });

    // Check query parameters to show dialog when returning from Stripe checkout redirect on Web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      try {
        final state = GoRouterState.of(context);
        final success = state.uri.queryParameters['success'];
        final plan = state.uri.queryParameters['plan'];
        if (success == 'true' && (plan == 'basic' || plan == 'premium')) {
          // Instantly clear query params from URL
          context.go('/subscription');
          // Show success dialog
          SubscriptionSuccessDialog.show(context, plan!);
        }
      } catch (_) {
        // Ignore if GoRouterState is not available
      }
    });

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
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/chat');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          fixedSize: const Size(48, 48),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Escolha Seu Plano',
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
                    children: [
                      ...PlanType.values.map((type) {
                        final isCurrentPlan = type.name == currentPlan;
                        return _PlanCard(
                          plan: type.entity,
                          tint: _planTint(type),
                          isLoading:
                              planState.isLoading && _loadingPlan == type,
                          isCurrentPlan: isCurrentPlan,
                          onSelect: isCurrentPlan || planState.isLoading
                              ? null
                              : () async {
                                  if (type == PlanType.free) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppColors.surface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: const Text(
                                          'Cancelar Assinatura?',
                                          style: TextStyle(
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        content: const Text(
                                          'Você perderá os recursos do seu plano atual imediatamente e voltará ao plano Gratuito.',
                                          style: TextStyle(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text(
                                              'Voltar',
                                              style: TextStyle(
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text(
                                              'Confirmar',
                                              style: TextStyle(
                                                color: AppColors.flame,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) return;

                                    setState(() {
                                      _loadingPlan = type;
                                    });
                                    try {
                                      await ref
                                          .read(subscriptionProvider.notifier)
                                          .cancelSubscription();
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _loadingPlan = null;
                                        });
                                      }
                                    }
                                  } else {
                                    if (type == PlanType.basic && currentPlan == 'premium') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppColors.surface,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: const Text(
                                            'Alterar para Plano Básico?',
                                            style: TextStyle(
                                              color: AppColors.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: const Text(
                                            'Você está mudando do plano Premium para o Plano Básico. Suas vantagens e o limite de perguntas serão reduzidos para 100 perguntas/mês imediatamente.',
                                            style: TextStyle(
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(false),
                                              child: const Text(
                                                'Voltar',
                                                style: TextStyle(
                                                  color: AppColors.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(true),
                                              child: const Text(
                                                'Confirmar',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm != true) return;
                                    }
                                    setState(() {
                                      _loadingPlan = type;
                                    });
                                    try {
                                      await ref
                                          .read(subscriptionProvider.notifier)
                                          .checkout(type);
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _loadingPlan = null;
                                        });
                                      }
                                    }
                                  }
                                },
                        );
                      }),
                      if (currentPlan != 'free') ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref
                                    .read(subscriptionProvider.notifier)
                                    .openCustomerPortal();
                              } catch (e) {
                                final cleanMsg = e.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                );
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao abrir portal: $cleanMsg',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.flame,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.credit_card_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Gerenciar cartões, faturamento ou cancelar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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
    this.isCurrentPlan = false,
  });

  final PlanEntity plan;
  final Color tint;
  final bool isLoading;
  final VoidCallback? onSelect;
  final bool isCurrentPlan;

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
              color: tint.withValues(alpha: isCurrentPlan ? 0.08 : 0.04),
              border: Border.all(
                color: tint.withValues(alpha: isCurrentPlan ? 0.3 : 0.12),
                width: isCurrentPlan ? 1.5 : 1,
              ),
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
                          Row(
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
                              if (isCurrentPlan) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: tint.withValues(alpha: 0.15),
                                  ),
                                  child: Text(
                                    'Atual',
                                    style: TextStyle(
                                      color: tint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                  text: plan.type == PlanType.free
                      ? '${plan.questionLimit} perguntas/semana'
                      : '${plan.questionLimit} perguntas/mês',
                  tint: tint,
                ),

                const SizedBox(height: 20),

                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: isCurrentPlan
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tint.withValues(alpha: 0.4),
                            side: BorderSide(
                              color: tint.withValues(alpha: 0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Plano Atual',
                            style: TextStyle(
                              color: tint.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: isLoading || onSelect == null
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  onSelect!();
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tint,
                            side: BorderSide(
                              color: tint.withValues(alpha: 0.25),
                            ),
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
