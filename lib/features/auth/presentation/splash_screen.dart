import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Initial check after the initial animation builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });
  }

  Future<void> _checkAuthAndRedirect() async {
    // ⚠️ FASE 1 MOCK: Artificial delay to show the logo fade-in
    // TODO: Remover isso na fase 2.
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Use current auth state for redirection
    final authState = ref.read(authProvider);

    authState.maybeWhen(
      authenticated: (_) => context.go('/chat'),
      orElse: () => context.go('/login'),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuta mudanças de authState para o caso de estar num loading longo.
    ref.listen(authProvider, (_, next) {
      if (!mounted) return;

      // TODO: Ajustar lógica na fase 2 caso aja um 'loading' global persistente.
      next.maybeWhen(
        authenticated: (_) => context.go('/chat'),
        unauthenticated: () => context.go('/login'),
        error: (_) => context.go('/login'),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
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
              child: Opacity(
                opacity: _glowAnim.value > 0.1 ? _glowAnim.value : 0,
                child: child,
              ),
            );
          },
          child: Image.asset('assets/images/logo.png', width: 140, height: 140),
        ),
      ),
    );
  }
}
