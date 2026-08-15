import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global provider for the currently logged-in user.
/// Derived from AuthState with instant synchronous fallback to Supabase session.
final userProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () {
      final sbUser = Supabase.instance.client.auth.currentUser;
      if (sbUser != null) {
        final meta = sbUser.userMetadata;
        return UserEntity(
          id: sbUser.id,
          email: sbUser.email ?? '',
          avatarUrl: meta?['avatar_url'] ?? meta?['picture'],
        );
      }
      return null;
    },
  );
});
