import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: swap back to AuthRemoteSource when Supabase is ready
import 'package:gnosis_chat/features/auth/data/auth_mock_source.dart';
import 'package:gnosis_chat/features/auth/data/auth_repository.dart';
import 'package:gnosis_chat/features/auth/domain/auth_state.dart';
import 'package:gnosis_chat/features/auth/domain/social_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(AuthMockSource()),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState.initial());

  final AuthRepository _repo;

  Future<void> signInWithProvider(SocialProvider provider) async {
    state = const AuthState.loading();
    try {
      final user = await _repo.signInWithProvider(provider);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signup(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await _repo.signup(email: email, password: password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }

  void unlockSecondChamber() {
    state.maybeWhen(
      authenticated: (user) {
        state = AuthState.authenticated(user.copyWith(chamberLevel: 2));
      },
      orElse: () {},
    );
  }

  void revertToFirstChamber() {
    state.maybeWhen(
      authenticated: (user) {
        state = AuthState.authenticated(user.copyWith(chamberLevel: 1));
      },
      orElse: () {},
    );
  }
}
