import 'package:gnosis_chat/features/auth/domain/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signup({required String email, required String password});
  Future<UserEntity> login({required String email, required String password});
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
}
