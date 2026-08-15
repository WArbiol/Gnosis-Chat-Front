import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gnosis_chat/features/auth/presentation/login_screen.dart';
import 'package:gnosis_chat/features/auth/presentation/splash_screen.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_shell.dart';
import 'package:gnosis_chat/features/subscription/presentation/subscription_screen.dart';
import 'package:gnosis_chat/features/chat/presentation/pdf_viewer_screen.dart';
import 'package:gnosis_chat/features/legal/presentation/privacy_policy_screen.dart';
import 'package:gnosis_chat/features/legal/presentation/terms_of_use_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/privacy',
      name: 'privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/terms',
      name: 'terms',
      builder: (context, state) => const TermsOfUseScreen(),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const ChatShell(),
    ),
    GoRoute(
      path: '/subscription',
      name: 'subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/pdf-viewer',
      name: 'pdf-viewer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final url = extra['url'] as String? ?? '';
        final bookName = extra['bookName'] as String? ?? '';
        final initialPage = extra['page'] as int? ?? 1;
        return PdfViewerScreen(
          url: url,
          bookName: bookName,
          initialPage: initialPage,
        );
      },
    ),
  ],
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/splash';
    final isPublicRoute =
        isAuthRoute ||
        state.matchedLocation == '/privacy' ||
        state.matchedLocation == '/terms';

    final uriStr = state.uri.toString();
    final isOAuthCallback =
        uriStr.contains('access_token=') ||
        uriStr.contains('refresh_token=') ||
        uriStr.contains('_=_');

    // Handle OAuth callback fragments: keep on /splash to let Supabase process tokens
    if (isOAuthCallback) {
      if (state.matchedLocation != '/splash') {
        return '/splash';
      }
      return null;
    }

    // We let splash screen be the entry point to resolve animations and slow auth fetches
    if (state.matchedLocation == '/splash') return null;

    // Allow public pages (privacy, terms) without authentication
    if (isPublicRoute) return null;

    // Let unauthenticated users go to login
    if (!isLoggedIn) return '/login';

    // Prevent authenticated users from going back to login
    if (isLoggedIn && isAuthRoute) return '/chat';

    return null;
  },
  errorBuilder: (context, state) => const SplashScreen(),
);
