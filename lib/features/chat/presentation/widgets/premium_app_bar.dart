import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';

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

  Widget _buildFallbackAvatar(String? email, double size, double fontSize) {
    final initial = (email != null && email.isNotEmpty) ? email[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.accent,
            AppColors.accentLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Sidebar / conversations icon
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Conversas',
            iconSize: 24,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              fixedSize: const Size(48, 48),
            ),
          ),

          const Spacer(),

          // Gold gradient title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.accent, AppColors.accentLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Gnosis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const Spacer(),

          // Profile avatar
          IconButton(
            onPressed: onProfileTap,
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                color: AppColors.surfaceVariant,
              ),
              child: ClipOval(
                child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                    ? Image.network(
                        user!.avatarUrl!,
                        headers: kIsWeb
                            ? null
                            : const {
                                'User-Agent':
                                    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                              },
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                            'DEBUG IMAGE: Failed to load avatar: $error',
                          );
                          return _buildFallbackAvatar(user?.email, 32, 14);
                        },
                      )
                    : _buildFallbackAvatar(user?.email, 32, 14),
              ),
            ),
            tooltip: 'Perfil',
            style: IconButton.styleFrom(fixedSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}
