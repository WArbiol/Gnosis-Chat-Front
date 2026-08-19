import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';
import 'package:gnosis_chat/shared/widgets/gnosis_liquid_glass.dart';
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
    if (!kIsWeb) {
      // Mobile native (Liquid Glass lens on Impeller / Native)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Menu Button with liquid touch response
            SizedBox(
              width: 44,
              height: 44,
              child: GnosisLiquidGlass(
                cornerRadius: 22,
                enableTouchFlex: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: onMenuTap,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 2.2,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4.5),
                          Container(
                            width: 13,
                            height: 2.2,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Gnosis Title Capsule
            GnosisLiquidGlass(
              cornerRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              enableTouchFlex: false,
              child: ShaderMask(
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
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Profile Avatar
            IconButton(
              onPressed: onProfileTap,
              icon: UserAvatar(
                avatarUrl: user?.avatarUrl,
                email: user?.email,
                size: 34,
                fontSize: 14,
                borderWidth: 1.5,
              ),
              tooltip: 'Perfil',
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
              ),
            ),
          ],
        ),
      );
    }

    // Web: The clean, flat, classic layout from yesterday
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Sidebar / conversations icon (48x48)
          SizedBox(
            width: 48,
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
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
            ),
          ),

          // Title centered in the middle between menu and profile
          Expanded(
            child: Center(
              child: ShaderMask(
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
            ),
          ),

          // Profile avatar (48x48)
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
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
          ),
        ],
      ),
    );
  }
}
