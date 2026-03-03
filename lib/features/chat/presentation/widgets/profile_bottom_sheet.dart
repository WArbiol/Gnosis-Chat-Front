import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/second_chamber_dialog.dart';
import 'package:gnosis_chat/shared/providers/user_provider.dart';

class ProfileBottomSheet extends ConsumerWidget {
  const ProfileBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final planLabel = _planLabel(user?.plan);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  color: AppColors.surfaceVariant,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: AppColors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                user?.email ?? 'Usuário',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              // Plan badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.15),
                      AppColors.accentLight.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  planLabel,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Chamber badge
              _ChamberBadge(chamberLevel: user?.chamberLevel ?? 1),

              const SizedBox(height: 28),

              // Manage Plan button
              _ActionTile(
                icon: Icons.workspace_premium_rounded,
                label: 'Gerenciar Plano',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/subscription');
                },
              ),

              const SizedBox(height: 8),

              // Chamber access toggle
              if ((user?.chamberLevel ?? 1) < 2) ...[
                _ActionTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Acessar conteúdos da 2ª Câmara',
                  onTap: () async {
                    final unlocked = await SecondChamberDialog.show(context);
                    if (unlocked == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚜️ Bem-vindo à 2ª Câmara!'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
              ] else ...[
                _ActionTile(
                  icon: Icons.lock_open_rounded,
                  label: 'Restringir acesso à 1ª Câmara',
                  onTap: () => _confirmRevert(context, ref),
                ),
                const SizedBox(height: 8),
              ],

              // Logout button
              _ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sair',
                isDestructive: true,
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sair da conta?',
          style: TextStyle(color: AppColors.onSurface),
        ),
        content: const Text(
          'Suas conversas serão perdidas ao sair.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Sair', style: TextStyle(color: AppColors.flame)),
          ),
        ],
      ),
    );
  }

  void _confirmRevert(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Restringir acesso?',
          style: TextStyle(color: AppColors.onSurface),
        ),
        content: const Text(
          'Você deixará de visualizar os conteúdos exclusivos da 2ª Câmara. Poderá solicitar acesso novamente a qualquer momento.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).revertToFirstChamber();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Acesso restrito à 1ª Câmara.'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Confirmar',
              style: TextStyle(color: AppColors.flame),
            ),
          ),
        ],
      ),
    );
  }

  static String _planLabel(String? plan) {
    return switch (plan) {
      'basic' => '✨ Plano Básico',
      'premium' => '👑 Plano Premium',
      _ => 'Plano Free',
    };
  }
}

// ---------------------------------------------------------------------------
// Chamber level badge
// ---------------------------------------------------------------------------
class _ChamberBadge extends StatelessWidget {
  const _ChamberBadge({required this.chamberLevel});

  final int chamberLevel;

  bool get _isSecond => chamberLevel >= 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _isSecond
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.surfaceVariant.withValues(alpha: 0.5),
        border: Border.all(
          color: _isSecond
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.onSurfaceVariant.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Text(
        _isSecond ? '⚜️ 2ª Câmara' : '⚜️ 1ª Câmara',
        style: TextStyle(
          color: _isSecond ? AppColors.accent : AppColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action tile
// ---------------------------------------------------------------------------
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.flame : AppColors.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.surfaceVariant.withValues(alpha: 0.4),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: color.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
