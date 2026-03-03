import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/features/auth/presentation/login_screen.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_shell.dart';
import 'package:gnosis_chat/features/subscription/presentation/subscription_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
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
  // TODO: add redirect guard for auth state
);
