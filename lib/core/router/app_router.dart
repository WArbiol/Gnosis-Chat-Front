import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gnosis_chat/features/auth/presentation/login_screen.dart';
import 'package:gnosis_chat/features/auth/presentation/splash_screen.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_shell.dart';
import 'package:gnosis_chat/features/subscription/presentation/subscription_screen.dart';

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

    // Handle Facebook's common quirk: it appends '_=_' to the URL
    // We catch it here globally and redirect to a clean state.
    if (state.uri.toString().contains('_=_')) {
      return isLoggedIn ? '/chat' : '/login';
    }

    // We let splash screen be the entry point to resolve animations and slow auth fetches
    if (state.matchedLocation == '/splash') return null;

    // Let unauthenticated users go to login
    if (!isLoggedIn && !isAuthRoute) return '/login';

    // Prevent authenticated users from going back to login
    if (isLoggedIn && isAuthRoute) return '/chat';

    return null;
  },
  errorBuilder: (context, state) => const LoginScreen(),
);
