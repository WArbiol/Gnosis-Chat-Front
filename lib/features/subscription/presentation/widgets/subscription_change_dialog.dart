import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';

class SubscriptionChangeDialog extends StatelessWidget {
  const SubscriptionChangeDialog({
    super.key,
    required this.currentPlan,
    required this.targetPlan,
  });

  final String currentPlan; // 'basic' or 'premium'
  final PlanType targetPlan; // PlanType.basic or PlanType.premium

  /// Shows the plan upgrade/downgrade confirmation dialog.
  /// Returns `true` if confirmed, `false` otherwise.
  static Future<bool?> show(
    BuildContext context, {
    required String currentPlan,
    required PlanType targetPlan,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SubscriptionChangeDialog(
        currentPlan: currentPlan,
        targetPlan: targetPlan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUpgrade = targetPlan == PlanType.premium;
    final primaryColor = isUpgrade ? AppColors.accent : AppColors.primary;
    final secondaryColor = isUpgrade ? AppColors.accentLight : AppColors.primaryLight;
    final emoji = isUpgrade ? '👑' : '✨';

    final title = isUpgrade ? 'Fazer Upgrade para Premium?' : 'Alterar para Plano Básico?';
    final subtitle = isUpgrade ? 'EXPANSÃO DE ACESSO' : 'AJUSTE DE PLANO';
    final targetPrice = isUpgrade ? 'R\$ 29,90/mês' : 'R\$ 9,90/mês';
    final targetQuota = isUpgrade ? '1.000 perguntas/mês' : '100 perguntas/mês';
    final explanation = isUpgrade
        ? 'Sua assinatura será atualizada para o Plano Premium. O novo valor será cobrado proporcionalmente e seu limite aumentará imediatamente.'
        : 'Você está mudando do plano Premium para o Plano Básico. Seu novo valor será de R\$ 9,90/mês e o limite de perguntas será ajustado para 100 perguntas/mês.';

    final confirmButtonText = isUpgrade ? 'Confirmar Upgrade' : 'Confirmar Alteração';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        tween: Tween<double>(begin: 0.85, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 50,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Icon Header
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.3),
                              primaryColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              secondaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Plan Details Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Novo Valor:',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              targetPrice,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Limite de Perguntas:',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              targetQuota,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: AppColors.onSurface.withValues(alpha: 0.1)),
                        const SizedBox(height: 12),
                        Text(
                          explanation,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop(false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurfaceVariant,
                              side: BorderSide(
                                color: AppColors.onSurface.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Voltar',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Confirm Button
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: isUpgrade ? Colors.black : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              confirmButtonText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
