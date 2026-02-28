import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/auth/data/auth_remote_source.dart';
import 'package:gnosis_chat/features/auth/domain/auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(AuthRemoteSource()),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState.initial());

  final AuthRemoteSource _repo;

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
}
