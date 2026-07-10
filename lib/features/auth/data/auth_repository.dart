import 'package:gnosis_chat/features/auth/domain/social_provider.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithProvider(SocialProvider provider);
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> signup({required String email, required String password});
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> updateProfile({int? chamberLevel});
  Future<Map<String, dynamic>> verifySecondChamber(String passcode);
}
