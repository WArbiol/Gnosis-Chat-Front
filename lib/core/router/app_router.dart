import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gnosis_chat/features/auth/presentation/login_screen.dart';
import 'package:gnosis_chat/features/auth/presentation/splash_screen.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_shell.dart';
import 'package:gnosis_chat/features/subscription/presentation/subscription_screen.dart';
import 'package:gnosis_chat/features/chat/presentation/pdf_viewer_screen.dart';

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
    // In GoRouter 5.0+ we cannot directly use ref.read indiscriminately inside redirect
    // without it being passed down, but assuming there is a global listener or
    // we just use Supabase session state synchronously for the initial checks.

    // Using Supabase directly for synchronous redirects avoids Provider scope issues in the router definition
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/splash';

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

    // Let unauthenticated users go to login
    if (!isLoggedIn && !isAuthRoute) return '/login';

    // Prevent authenticated users from going back to login
    if (isLoggedIn && isAuthRoute) return '/chat';

    return null;
  },
  errorBuilder: (context, state) => const SplashScreen(),
);
