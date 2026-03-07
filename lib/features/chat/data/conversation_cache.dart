import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/chat/domain/conversation_entity.dart';
import 'package:hive_flutter/hive_flutter.dart';

final conversationCacheProvider = Provider<ConversationCache>((ref) {
  return ConversationCache();
});

class ConversationCache {
  static const String boxName = 'conversations_box';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  /// Check if cache has data
  bool get hasData => _box?.isNotEmpty ?? false;

  /// Loads cached conversations
  List<ConversationEntity> loadConversations() {
    if (_box == null || _box!.isEmpty) return [];

    final list = _box!.values.toList();
    final items = list.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Handle the fact that our freezed entity might need manual conversion of dates in some edge cases
      // though json_serializable usually handles that well if the string is ISO8601
      return ConversationEntity.fromJson(map);
    }).toList();

    // Sort descending by updated_at
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  /// Replace the whole list over the local cache
  Future<void> saveConversations(List<ConversationEntity> conversations) async {
    if (_box == null) return;

    await _box!.clear();

    final mapToSave = {
      for (var c in conversations) c.id: jsonEncode(c.toJson()),
    };

    await _box!.putAll(mapToSave);
  }

  /// Update or add a single item
  Future<void> saveSingle(ConversationEntity conversation) async {
    if (_box == null) return;
    await _box!.put(conversation.id, jsonEncode(conversation.toJson()));
  }

  /// Delete single item
  Future<void> deleteSingle(String id) async {
    if (_box == null) return;
    await _box!.delete(id);
  }

  /// Clear all cache
  Future<void> clear() async {
    await _box?.clear();
  }
}
