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

  Box<String> get _openBox {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(boxName)) return Hive.box<String>(boxName);
    return _box!;
  }

  /// Check if cache has data
  bool get hasData {
    try {
      return _openBox.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Loads cached conversations
  List<ConversationEntity> loadConversations() {
    try {
      final box = _openBox;
      if (box.isEmpty) return [];

      final list = box.values.toList();
      final items = list.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return ConversationEntity.fromJson(map);
      }).toList();

      // Sort: pinned first (descending), then updated_at (descending)
      items.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Replace the whole list over the local cache
  Future<void> saveConversations(List<ConversationEntity> conversations) async {
    try {
      final box = _openBox;
      await box.clear();

      final mapToSave = {
        for (var c in conversations) c.id: jsonEncode(c.toJson()),
      };

      await box.putAll(mapToSave);
    } catch (_) {}
  }

  /// Update or add a single item
  Future<void> saveSingle(ConversationEntity conversation) async {
    try {
      await _openBox.put(conversation.id, jsonEncode(conversation.toJson()));
    } catch (_) {}
  }

  /// Delete single item
  Future<void> deleteSingle(String id) async {
    try {
      await _openBox.delete(id);
    } catch (_) {}
  }

  /// Clear all cache
  Future<void> clear() async {
    try {
      await _openBox.clear();
    } catch (_) {}
  }
}
