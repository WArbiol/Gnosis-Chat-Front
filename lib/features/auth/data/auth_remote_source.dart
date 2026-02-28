import 'package:gnosis_chat/features/auth/data/auth_repository.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';

class AuthRemoteSource implements AuthRepository {
  // TODO: inject Supabase client

  @override
  Future<UserEntity> signup({
    required String email,
    required String password,
  }) async {
    // TODO: Supabase.instance.client.auth.signUp(email: email, password: password)
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    // TODO: Supabase.instance.client.auth.signInWithPassword(...)
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    // TODO: Supabase.instance.client.auth.signOut()
    throw UnimplementedError();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // TODO: Supabase.instance.client.auth.currentUser
    return null;
  }
}
