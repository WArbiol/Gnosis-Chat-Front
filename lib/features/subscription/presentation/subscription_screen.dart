import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';
import 'package:gnosis_chat/features/subscription/presentation/subscription_provider.dart';
import 'package:gnosis_chat/features/subscription/presentation/widgets/subscription_cancel_dialog.dart';
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

  Future<void> _reactivateSubscription() async {
    setState(() {
      _loadingPlan = PlanType.basic;
    });
    try {
      await ref.read(subscriptionProvider.notifier).reactivateSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assinatura reativada com sucesso! 🚀'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reativar: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.flame,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingPlan = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(subscriptionProvider);
    final currentUser = ref.watch(userProvider);
    final currentPlan = currentUser?.plan ?? 'free';
    final isCanceled = currentUser?.subscriptionStatus == 'canceled';
    final subscriptionProviderName = currentUser?.subscriptionProvider;

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
                      if (isCanceled && currentPlan != 'free') ...[
                        _CanceledBanner(
                          planName: currentPlan == 'premium'
                              ? 'Plano Premium'
                              : 'Plano Básico',
                          currentPeriodEnd: currentUser?.currentPeriodEnd,
                        ),
                        const SizedBox(height: 16),
                      ],
                      ...PlanType.values.map((type) {
                        final isCurrentPlan = type.name == currentPlan;
                        return _PlanCard(
                          plan: type.entity,
                          tint: _planTint(type),
                          isLoading:
                              planState.isLoading && _loadingPlan == type,
                          isCurrentPlan: isCurrentPlan,
                          isCanceled: isCurrentPlan && isCanceled,
                          onReactivate: _reactivateSubscription,
                          onSelect: isCurrentPlan || planState.isLoading
                              ? null
                              : () async {
                                  if (currentPlan != 'free' && _checkPlatformMismatch(subscriptionProviderName)) {
                                    return;
                                  }
                                  if (type == PlanType.free) {
                                    final planTitle = currentPlan == 'premium'
                                        ? 'Plano Premium'
                                        : 'Plano Básico';
                                    final confirm = await SubscriptionCancelDialog.show(
                                      context,
                                      planName: planTitle,
                                      currentPeriodEnd: currentUser?.currentPeriodEnd,
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
                              if (_checkPlatformMismatch(subscriptionProviderName)) return;
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

  bool _checkPlatformMismatch(String? provider) {
    if (provider == null) return false;
    if (provider == 'apple' && kIsWeb) {
      _showWarning('Sua assinatura é gerenciada pela Apple. Acesse os Ajustes do seu iPhone para alterá-la.');
      return true;
    } else if (provider == 'google' && kIsWeb) {
      _showWarning('Sua assinatura é gerenciada pelo Google. Acesse a Play Store para alterá-la.');
      return true;
    } else if (provider == 'stripe' && !kIsWeb) {
      _showWarning('Sua assinatura é gerenciada via Web. Acesse gnosis-chat.app no navegador para alterá-la.');
      return true;
    }
    return false;
  }

  void _showWarning(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Gerenciamento de Assinatura', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendi', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
    this.isCanceled = false,
    this.onReactivate,
  });

  final PlanEntity plan;
  final Color tint;
  final bool isLoading;
  final VoidCallback? onSelect;
  final bool isCurrentPlan;
  final bool isCanceled;
  final VoidCallback? onReactivate;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isCanceled ? AppColors.flame : tint;

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
                color: (isCanceled ? AppColors.flame : tint).withValues(alpha: isCurrentPlan ? 0.35 : 0.12),
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
                                    color: badgeColor.withValues(alpha: 0.15),
                                  ),
                                  child: Text(
                                    isCanceled ? 'Cancelada' : 'Atual',
                                    style: TextStyle(
                                      color: badgeColor,
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
                      ? (isCanceled
                          ? ElevatedButton.icon(
                              onPressed: isLoading || onReactivate == null
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      onReactivate!();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.background,
                                      ),
                                    )
                                  : const Icon(Icons.bolt_rounded, size: 18),
                              label: const Text(
                                'Reativar Assinatura',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            )
                          : OutlinedButton(
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
                            ))
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

// ---------------------------------------------------------------------------
// Canceled Banner widget — shown when subscription cancellation is pending
// ---------------------------------------------------------------------------
class _CanceledBanner extends StatelessWidget {
  const _CanceledBanner({
    required this.planName,
    required this.currentPeriodEnd,
  });

  final String planName;
  final String? currentPeriodEnd;

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'o final do período';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      return '$day/$month/$year';
    } catch (_) {
      return 'o final do período';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(currentPeriodEnd);
    const accent = AppColors.flame;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assinatura Cancelada',
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Expira em $dateStr',
                          style: const TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Seu acesso ao $planName continua 100% ativo. Você pode reativar a renovação automática a qualquer momento.',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

