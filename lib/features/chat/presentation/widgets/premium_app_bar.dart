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

    // Web: Clean flat glass with balanced opacity and "Gnosis" capsule (Optimized for 60 FPS)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Menu button (sleek dark glass with zero blur overhead)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xF218181C),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onMenuTap,
                child: const Center(
                  child: Icon(
                    Icons.menu_rounded,
                    color: AppColors.onSurface,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // 2. Gnosis Title Capsule on Web
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xF218181C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              'Gnosis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.accentLight,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // 3. Profile Avatar
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
}
