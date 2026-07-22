import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/chat/data/conversation_cache.dart';
import 'package:gnosis_chat/features/chat/data/conversation_remote_source.dart';
import 'package:gnosis_chat/features/chat/domain/conversation_entity.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/services/api/api_client.dart';

final conversationRemoteSourceProvider = Provider<ConversationRemoteSource>((
  ref,
) {
  final api = ref.watch(apiClientProvider);
  return ConversationRemoteSource(api.dio);
});

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
      final repo = ref.watch(conversationRemoteSourceProvider);
      final cache = ref.watch(conversationCacheProvider);
      return ConversationNotifier(ref, repo, cache)..loadConversations();
    });

class ConversationState {
  const ConversationState({this.conversations = const [], this.activeId});

  final List<ConversationEntity> conversations;
  final String? activeId;

  ConversationEntity? get active => activeId == null
      ? null
      : conversations.where((c) => c.id == activeId).firstOrNull;

  ConversationState copyWith({
    List<ConversationEntity>? conversations,
    String? Function()? activeId,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      activeId: activeId != null ? activeId() : this.activeId,
    );
  }
}

class ConversationNotifier extends StateNotifier<ConversationState> {
  ConversationNotifier(this._ref, this._repo, this._cache)
    : super(const ConversationState());

  final Ref _ref;
  final ConversationRemoteSource _repo;
  final ConversationCache _cache;

  Future<void> loadConversations() async {
    // 1. Load from offline cache immediately for fast UI
    if (_cache.hasData) {
      final cachedList = _cache.loadConversations();
      state = state.copyWith(conversations: cachedList);
      // NOTE: We no longer auto-select the first conversation on startup (Option A: Always New Chat)
    }

    // 2. Fetch fresh data from backend
    try {
      final list = await _repo.listConversations();
      state = state.copyWith(conversations: list);

      // Save full list to cache
      await _cache.saveConversations(list);

      // NOTE: We no longer auto-select the first conversation on startup (Option A: Always New Chat)
    } catch (e) {
      // Handle error cleanly, rely on cached state
    }
  }

  /// Resets the active conversation to null (Draft state) without calling the backend.
  void resetActiveId() {
    state = state.copyWith(activeId: () => null);
    _ref.read(chatProvider.notifier).clearHistory();
    debugPrint('CONV: Active state reset to Draft');
  }

  /// Creates a new empty conversation and activates it.
  Future<void> createConversation() async {
    debugPrint('CONV: Starting createConversation...');
    try {
      final conv = await _repo.createConversation('Nova conversa');
      debugPrint('CONV: Created ID: ${conv.id}');
      state = state.copyWith(
        conversations: [conv, ...state.conversations],
        activeId: () => conv.id,
      );

      await _cache.saveSingle(conv);

      // We clear history only if we were NOT in the middle of sending a message
      // But usually, JIT ask() calls this BEFORE adding the optimistic message.
      _ref.read(chatProvider.notifier).clearHistory();
      debugPrint('CONV: State updated with activeId: ${conv.id}');
    } catch (e, stack) {
      debugPrint('CONV: ERROR creating conversation: $e');
      debugPrint(stack.toString());
    }
  }

  /// Selects an existing conversation and loads its messages from the backend.
  Future<void> selectConversation(String id) async {
    final existingConv = state.conversations
        .where((c) => c.id == id)
        .firstOrNull;
    if (existingConv == null) return;

    state = state.copyWith(activeId: () => id);

    // 1. Instant optimistic load from memory/cache (0ms delay, no blank screen flicker!)
    if (existingConv.messages.isNotEmpty) {
      _ref.read(chatProvider.notifier).loadMessages(existingConv.messages);
    } else {
      _ref.read(chatProvider.notifier).setLoadingState();
    }

    try {
      // 2. Fetch fresh details from backend asynchronously
      final fullConv = await _repo.getConversation(id);

      // Only update chatProvider UI if this conversation is still the active one!
      if (state.activeId == id) {
        _ref.read(chatProvider.notifier).loadMessages(fullConv.messages);
      }

      // Update local state with the loaded messages
      syncMessagesForId(id, fullConv.messages);
    } catch (e) {
      debugPrint('CONV: Error fetching conversation details: $e');
    }
  }

  /// Deletes a conversation from remote and local state.
  Future<void> deleteConversation(String id) async {
    final wasActive = state.activeId == id;
    final updated = state.conversations.where((c) => c.id != id).toList();

    state = state.copyWith(
      conversations: updated,
      activeId: wasActive ? () => null : null,
    );

    if (wasActive) {
      _ref.read(chatProvider.notifier).clearHistory();
    }

    try {
      await _repo.deleteConversation(id);
      await _cache.deleteSingle(id);
    } catch (e) {
      // Optionally rollback state or show error
    }
  }

  /// Updates the active conversation with the current chat messages locally.
  /// (Called repeatedly by ChatNotifier for instant UI).
  void syncMessages(List<MessageEntity> messages) {
    if (state.activeId == null) return;
    syncMessagesForId(state.activeId!, messages);
  }

  /// Updates a specific conversation by ID with messages locally.
  void syncMessagesForId(String targetId, List<MessageEntity> messages) {
    final updated = state.conversations.map((c) {
      if (c.id != targetId) return c;

      final title = messages.isNotEmpty
          ? _truncate(messages.first.content, 40)
          : 'Nova conversa';

      // Self-healing: if the backend title is still "Nova conversa" but we have content,
      // push the calculated title to the server to fix it permanently.
      if (title != 'Nova conversa' && c.title == 'Nova conversa') {
        _repo.updateConversation(c.id, title).catchError((e) {
          debugPrint('CONV: Failed to push self-healing title: $e');
          return c; // Return current as fallback to satisfy type
        });
      }

      final lastPreview = messages.isNotEmpty ? messages.last.content : null;

      return c.copyWith(
        messages: messages,
        messageCount: messages.length,
        lastMessagePreview: lastPreview,
        title: title,
        updatedAt: DateTime.now(),
      );
    }).toList();

    state = state.copyWith(conversations: updated);

    final targetConv = updated.where((c) => c.id == targetId).firstOrNull;
    if (targetConv != null) {
      _cache.saveSingle(targetConv);
    }
  }

  /// Searches conversations by title (case-insensitive).
  List<ConversationEntity> search(String query) {
    if (query.isEmpty) return state.conversations;
    final lower = query.toLowerCase();
    return state.conversations
        .where((c) => c.title.toLowerCase().contains(lower))
        .toList();
  }

  void clearAll() {
    state = const ConversationState();
    _cache.clear(); // I'll need to add this to ConversationCache
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }
}
