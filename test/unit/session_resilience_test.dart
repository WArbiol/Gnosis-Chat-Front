import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/features/auth/data/user_cache.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late UserCache userCache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('user_cache_test_');
    Hive.init(tempDir.path);
    userCache = UserCache();
    await userCache.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('UserCache Resilience Tests', () {
    test('starts with hasData == false and loadUser() == null', () {
      expect(userCache.hasData, isFalse);
      expect(userCache.loadUser(), isNull);
    });

    test('saves and loads UserEntity with Premium plan and chamber level accurately', () async {
      const user = UserEntity(
        id: 'usr-123',
        email: 'walter@gnosis.ai',
        avatarUrl: 'https://example.com/avatar.png',
        plan: 'premium',
        chamberLevel: 2,
        questionCount: 42,
        subscriptionStatus: 'active',
      );

      await userCache.saveUser(user);

      expect(userCache.hasData, isTrue);

      final loaded = userCache.loadUser();
      expect(loaded, isNotNull);
      expect(loaded!.id, 'usr-123');
      expect(loaded.email, 'walter@gnosis.ai');
      expect(loaded.plan, 'premium');
      expect(loaded.chamberLevel, 2);
      expect(loaded.questionCount, 42);
      expect(loaded.subscriptionStatus, 'active');
    });

    test('clears user profile on clear()', () async {
      const user = UserEntity(
        id: 'usr-123',
        email: 'walter@gnosis.ai',
        plan: 'basic',
      );

      await userCache.saveUser(user);
      expect(userCache.hasData, isTrue);

      await userCache.clear();
      expect(userCache.hasData, isFalse);
      expect(userCache.loadUser(), isNull);
    });
  });
}
