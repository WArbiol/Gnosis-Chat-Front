import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Check immediately if already logged in
    var session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go('/chat');
      return;
    }

    // Wait up to 3 seconds for Supabase to finish parsing OAuth tokens from the URL fragment
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        context.go('/chat');
        return;
      }
    }

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We let Supabase state changes trigger GoRouter redirect via app_router
    // The riverpod listen below is not strictly required if GoRouter handles it.

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
