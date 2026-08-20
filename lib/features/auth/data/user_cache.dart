import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';
import 'package:hive_flutter/hive_flutter.dart';

final userCacheProvider = Provider<UserCache>((ref) {
  return UserCache();
});

class UserCache {
  static const String boxName = 'user_box';
  static const String _userKey = 'current_user';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  Box<String> get _openBox => _box ?? Hive.box<String>(boxName);

  /// Check if a cached user profile exists
  bool get hasData {
    try {
      return _openBox.containsKey(_userKey);
    } catch (_) {
      return false;
    }
  }

  /// Load cached UserEntity
  UserEntity? loadUser() {
    try {
      final jsonStr = _openBox.get(_userKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserEntity.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Save UserEntity to local cache
  Future<void> saveUser(UserEntity user) async {
    try {
      await _openBox.put(_userKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  /// Clear cached user profile on logout
  Future<void> clear() async {
    try {
      await _openBox.delete(_userKey);
    } catch (_) {}
  }
}
