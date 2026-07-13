import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/domain/social_provider.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:gnosis_chat/shared/widgets/animated_background.dart';
import 'package:gnosis_chat/shared/widgets/google_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;
  SocialProvider? _loadingProvider;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn(SocialProvider provider) async {
    setState(() => _loadingProvider = provider);
    await ref.read(authProvider.notifier).signInWithProvider(provider);
    if (mounted) setState(() => _loadingProvider = null);
  }

  bool get _showApple =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) {
      next.whenOrNull(
        authenticated: (_) => context.go('/chat'),
        error: (msg) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient blobs for glass effect
          AnimatedBackground(animation: _glowAnim, showTopLeftGold: false),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Logo with animated glow
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(
                                  alpha: _glowAnim.value * 0.5,
                                ),
                                blurRadius: 70,
                                spreadRadius: 25,
                              ),
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: _glowAnim.value * 0.25,
                                ),
                                blurRadius: 90,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 140,
                        height: 140,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Title with gold gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Gnosis',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Conhecimento sagrado revelado.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 56),

                    // Glass panel with social buttons
                    _GlassPanel(
                      child: Column(
                        children: [
                          _GlassSocialButton(
                            label: 'Continuar com Google',
                            icon: const GoogleLogo(size: 22),
                            isLoading:
                                _loadingProvider == SocialProvider.google,
                            isDisabled: _loadingProvider != null,
                            onTap: () => _signIn(SocialProvider.google),
                          ),
                          const SizedBox(height: 12),
                          _GlassSocialButton(
                            label: 'Continuar com Facebook',
                            icon: const Icon(
                              Icons.facebook_rounded,
                              color: Color(0xFF1877F2),
                              size: 24,
                            ),
                            isLoading:
                                _loadingProvider == SocialProvider.facebook,
                            isDisabled: _loadingProvider != null,
                            onTap: () => _signIn(SocialProvider.facebook),
                          ),
                          if (_showApple) ...[
                            const SizedBox(height: 12),
                            _GlassSocialButton(
                              label: 'Continuar com Apple',
                              icon: const Icon(
                                Icons.apple_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              isLoading:
                                  _loadingProvider == SocialProvider.apple,
                              isDisabled: _loadingProvider != null,
                              onTap: () => _signIn(SocialProvider.apple),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    Text(
                      'Ao continuar, você concorda com os Termos de Uso\ne a Política de Privacidade.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted-glass container panel.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Individual social login button with frosted-glass style.
class _GlassSocialButton extends StatelessWidget {
  const _GlassSocialButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.accent.withValues(alpha: 0.1),
            highlightColor: AppColors.accent.withValues(alpha: 0.05),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(
                  alpha: isDisabled && !isLoading ? 0.03 : 0.08,
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: isDisabled && !isLoading ? 0.05 : 0.12,
                  ),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accent,
                      ),
                    )
                  else
                    SizedBox(width: 24, height: 24, child: Center(child: icon)),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: isDisabled && !isLoading ? 0.4 : 0.9,
                        ),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
