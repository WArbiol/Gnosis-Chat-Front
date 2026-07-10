import 'package:gnosis_chat/features/auth/data/auth_repository.dart';
import 'package:gnosis_chat/features/auth/domain/social_provider.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';

/// Mock auth source for local development.
/// Swap to [AuthRemoteSource] when Supabase is ready.
class AuthMockSource implements AuthRepository {
  UserEntity? _currentUser;

  @override
  Future<UserEntity> signInWithProvider(SocialProvider provider) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final email = 'user@${provider.name}.mock';
    _currentUser = UserEntity(
      id: 'mock-${provider.name}-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
    );
    return _currentUser!;
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = UserEntity(id: 'mock-${email.hashCode}', email: email);
    return _currentUser!;
  }

  @override
  Future<UserEntity> signup({
    required String email,
    required String password,
  }) async {
    return login(email: email, password: password);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserEntity> updateProfile({int? chamberLevel}) async {
    if (_currentUser == null) throw Exception('Mock user not logged in');
    _currentUser = _currentUser!.copyWith(
      chamberLevel: chamberLevel ?? _currentUser!.chamberLevel,
    );
    return _currentUser!;
  }

  @override
  Future<Map<String, dynamic>> verifySecondChamber(String passcode) async {
    if (_currentUser == null) throw Exception('Mock user not logged in');
    final cleaned = passcode.toLowerCase().trim();
    final isValid = cleaned.contains('paz') || cleaned.contains('pas') || cleaned.contains('pax');
    if (isValid) {
      _currentUser = _currentUser!.copyWith(chamberLevel: 2);
    }
    return {
      'valid': isValid,
      'reason': isValid ? 'Sucesso' : 'Passe incorreto.',
      'user': _currentUser!.toJson(),
    };
  }
}
