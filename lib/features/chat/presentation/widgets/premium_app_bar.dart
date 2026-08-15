import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';
import 'package:gnosis_chat/shared/widgets/user_avatar.dart';

class PremiumAppBar extends StatelessWidget {
  const PremiumAppBar({
    super.key,
    required this.glowAnim,
    this.user,
    this.onMenuTap,
    this.onProfileTap,
  });

  final Animation<double> glowAnim;
  final UserEntity? user;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.75),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.8,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
        children: [
          // Sidebar / conversations icon
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Conversas',
              iconSize: 22,
              style: IconButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title with subtle gold gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                AppColors.accent,
                AppColors.accentLight,
                AppColors.accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Gnosis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const Spacer(),

          // Profile avatar
          IconButton(
            onPressed: onProfileTap,
            icon: UserAvatar(
              avatarUrl: user?.avatarUrl,
              email: user?.email,
              size: 32,
              fontSize: 14,
              borderWidth: 1.5,
            ),
            tooltip: 'Perfil',
            style: IconButton.styleFrom(fixedSize: const Size(48, 48)),
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
