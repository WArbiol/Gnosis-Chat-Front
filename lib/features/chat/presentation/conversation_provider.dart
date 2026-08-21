import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/chat/data/conversation_cache.dart';
import 'package:gnosis_chat/features/chat/data/conversation_remote_source.dart';
import 'package:gnosis_chat/features/chat/domain/conversation_entity.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/services/api/api_client.dart';

import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';

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
      final notifier = ConversationNotifier(ref, repo, cache)..loadConversations();

      // Automatically reload conversations whenever user is authenticated or session refreshes
      ref.listen(authProvider, (previous, next) {
        next.maybeWhen(
          authenticated: (_) {
            notifier.loadConversations();
          },
          orElse: () {},
        );
      });

      return notifier;
    });

class ConversationState {
  const ConversationState({
    this.conversations = const [],
    this.activeId,
    this.isLoading = false,
  });

  final List<ConversationEntity> conversations;
  final String? activeId;
  final bool isLoading;

  ConversationEntity? get active => activeId == null
      ? null
      : conversations.where((c) => c.id == activeId).firstOrNull;

  ConversationState copyWith({
    List<ConversationEntity>? conversations,
    String? Function()? activeId,
    bool? isLoading,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      activeId: activeId != null ? activeId() : this.activeId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ConversationNotifier extends StateNotifier<ConversationState> {
  ConversationNotifier(this._ref, this._repo, this._cache)
    : super(
        ConversationState(
          conversations: _cache.loadConversations(),
          isLoading: _cache.loadConversations().isEmpty,
        ),
      );

  final Ref _ref;
  final ConversationRemoteSource _repo;
  final ConversationCache _cache;

  List<ConversationEntity> _sortConversations(List<ConversationEntity> list) {
    final sorted = List<ConversationEntity>.from(list);
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sorted;
  }

  Future<void> loadConversations() async {
    // 1. Load from offline cache immediately for fast UI
    final cachedList = _cache.loadConversations();
    if (cachedList.isNotEmpty) {
      state = state.copyWith(
        conversations: _sortConversations(cachedList),
        isLoading: false,
      );
    }

    // 2. Fetch fresh data from backend
    try {
      final list = await _repo.listConversations();

      // Merge remote list with cached/in-memory conversations to preserve offline messages
      final merged = list.map((remoteConv) {
        final existing = state.conversations
                .where((c) => c.id == remoteConv.id)
                .firstOrNull ??
            cachedList.where((c) => c.id == remoteConv.id).firstOrNull;
        if (existing != null && existing.messages.isNotEmpty) {
          final effectiveTitle = (remoteConv.title.isNotEmpty && remoteConv.title != 'Nova conversa')
              ? remoteConv.title
              : existing.title;
          return remoteConv.copyWith(
            title: effectiveTitle,
            messages: existing.messages,
            messageCount: existing.messages.length,
            lastMessagePreview: existing.lastMessagePreview ??
                (existing.messages.isNotEmpty
                    ? existing.messages.last.content
                    : null),
          );
        }
        return remoteConv;
      }).toList();

      final sorted = _sortConversations(merged);
      state = state.copyWith(conversations: sorted, isLoading: false);

      // Save merged list to cache
      await _cache.saveConversations(sorted);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Handle error cleanly, rely on cached state
    }
  }

  Timer? _pollingTimer;

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _startPollingFor(String id) {
    _stopPolling();
    debugPrint('CONV: Starting background polling for incomplete conversation: $id');
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (state.activeId != id) {
        _stopPolling();
        return;
      }

      try {
        final fullConv = await _repo.getConversation(id);
        if (state.activeId != id) {
          _stopPolling();
          return;
        }

        // Check if assistant has replied
        if (fullConv.messages.isNotEmpty && fullConv.messages.last.role == MessageRole.assistant) {
          debugPrint('CONV: Polling received assistant response for $id!');
          _stopPolling();
          _ref.read(chatProvider.notifier).loadMessages(fullConv.messages);
          syncMessagesForId(
            id,
            fullConv.messages,
            explicitTitle: fullConv.title.isNotEmpty && fullConv.title != 'Nova conversa'
                ? fullConv.title
                : null,
          );
        }
      } catch (e) {
        debugPrint('CONV: Error during polling for $id: $e');
      }
    });
  }

  /// Resets the active conversation to null (Draft state) without calling the backend.
  void resetActiveId() {
    _stopPolling();
    _ref.read(chatProvider.notifier).cancelActiveStream();
    state = state.copyWith(activeId: () => null);
    _ref.read(chatProvider.notifier).clearHistory();
    debugPrint('CONV: Active state reset to Draft');
  }

  /// Creates a new empty conversation and activates it.
  Future<void> createConversation() async {
    _stopPolling();
    debugPrint('CONV: Starting createConversation...');
    try {
      final conv = await _repo.createConversation('Nova conversa');
      debugPrint('CONV: Created ID: ${conv.id}');
      state = state.copyWith(
        conversations: [conv, ...state.conversations],
        activeId: () => conv.id,
      );

      await _cache.saveSingle(conv);

      debugPrint('CONV: State updated with activeId: ${conv.id}');
    } catch (e, stack) {
      debugPrint('CONV: ERROR creating conversation: $e');
      debugPrint(stack.toString());
    }
  }

  /// Selects an existing conversation and loads its messages from the backend.
  Future<void> selectConversation(String id) async {
    _stopPolling();
    _ref.read(chatProvider.notifier).cancelActiveStream();
    // Set activeId immediately so UI leaves "Draft" state right away
    state = state.copyWith(activeId: () => id);

    final existingConv = state.conversations
        .where((c) => c.id == id)
        .firstOrNull;

    // 1. Instant optimistic load from memory/cache if available
    if (existingConv != null && existingConv.messages.isNotEmpty) {
      _ref.read(chatProvider.notifier).loadMessages(existingConv.messages);
      if (existingConv.messages.last.role == MessageRole.user) {
        _startPollingFor(id);
      }
    } else {
      _ref.read(chatProvider.notifier).setLoadingState();
    }

    try {
      // 2. Fetch fresh details from backend asynchronously
      final fullConv = await _repo.getConversation(id);

      // Only update chatProvider UI if this conversation is still the active one!
      if (state.activeId == id) {
        _ref.read(chatProvider.notifier).loadMessages(fullConv.messages);
        if (fullConv.messages.isNotEmpty && fullConv.messages.last.role == MessageRole.user) {
          _startPollingFor(id);
        } else {
          _stopPolling();
        }
      }

      // Update local state with the loaded messages and remote title
      syncMessagesForId(
        id,
        fullConv.messages,
        explicitTitle: fullConv.title.isNotEmpty && fullConv.title != 'Nova conversa'
            ? fullConv.title
            : null,
      );
    } catch (e, st) {
      debugPrint('CONV: Error fetching conversation details: $e');
      if (state.activeId == id) {
        final currentMsgs = _ref.read(chatProvider).valueOrNull ?? [];
        if (currentMsgs.isEmpty) {
          _ref.read(chatProvider.notifier).setErrorState(e, st);
        }
      }
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
  void syncMessagesForId(
    String targetId,
    List<MessageEntity> messages, {
    String? explicitTitle,
  }) {
    final exists = state.conversations.any((c) => c.id == targetId);

    List<ConversationEntity> updated;
    if (exists) {
      updated = state.conversations.map((c) {
        if (c.id != targetId) return c;

        // Preserve existing title if it has been customized/AI-generated
        String title = explicitTitle ?? c.title;
        if (explicitTitle == null && (title == 'Nova conversa' || title == 'Conversa' || title.isEmpty)) {
          if (messages.isNotEmpty) {
            title = _truncate(messages.first.content, 40);
          }
        }

        // Self-healing: if the backend title is still "Nova conversa" but we have full content (user + AI),
        // push the calculated title to the server to fix it permanently.
        if (title != 'Nova conversa' && c.title == 'Nova conversa' && messages.length >= 2) {
          _repo.updateConversation(c.id, title: title).catchError((e) {
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
    } else {
      final title = explicitTitle ??
          (messages.isNotEmpty ? _truncate(messages.first.content, 40) : 'Conversa');
      final newConv = ConversationEntity(
        id: targetId,
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: messages,
        messageCount: messages.length,
        lastMessagePreview: messages.isNotEmpty ? messages.last.content : null,
      );
      updated = [newConv, ...state.conversations];
    }

    state = state.copyWith(conversations: _sortConversations(updated));

    final targetConv = updated.where((c) => c.id == targetId).firstOrNull;
    if (targetConv != null) {
      _cache.saveSingle(targetConv);
    }
  }

  /// Updates a specific citation's snippet in memory and persists to Hive for instant offline reuse
  void updateCitationSnippet(String citationId, String snippet) {
    if (citationId.isEmpty || snippet.isEmpty) return;

    final activeId = state.activeId;
    if (activeId == null) return;

    final currentMsgs = _ref.read(chatProvider).valueOrNull ?? [];
    bool messageUpdated = false;
    final updatedMsgs = currentMsgs.map((msg) {
      final hasCit = msg.citations.any((c) => c.id == citationId);
      if (hasCit) {
        messageUpdated = true;
        final updatedCits = msg.citations.map((c) {
          if (c.id == citationId) {
            return c.copyWith(snippet: snippet);
          }
          return c;
        }).toList();
        return msg.copyWith(citations: updatedCits);
      }
      return msg;
    }).toList();

    if (messageUpdated) {
      _ref.read(chatProvider.notifier).loadMessages(updatedMsgs);
      syncMessagesForId(activeId, updatedMsgs);
    }
  }

  /// Toggle pin status for a conversation (pinned to top)
  Future<void> togglePinConversation(String id) async {
    final conv = state.conversations.where((c) => c.id == id).firstOrNull;
    if (conv == null) return;

    final newPinned = !conv.isPinned;
    final updatedList = state.conversations.map((c) {
      if (c.id == id) {
        return c.copyWith(isPinned: newPinned);
      }
      return c;
    }).toList();

    final sorted = _sortConversations(updatedList);
    state = state.copyWith(conversations: sorted);
    await _cache.saveConversations(sorted);

    try {
      await _repo.updateConversation(id, isPinned: newPinned);
    } catch (e) {
      debugPrint('CONV: Failed to update pin status remotely: $e');
      // Revert if failed
      final reverted = state.conversations.map((c) {
        if (c.id == id) {
          return c.copyWith(isPinned: !newPinned);
        }
        return c;
      }).toList();
      final revertedSorted = _sortConversations(reverted);
      state = state.copyWith(conversations: revertedSorted);
      await _cache.saveConversations(revertedSorted);
    }
  }

  /// Rename conversation
  Future<void> renameConversation(String id, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    final oldConv = state.conversations.where((c) => c.id == id).firstOrNull;
    if (oldConv == null || oldConv.title == trimmed) return;

    final updatedList = state.conversations.map((c) {
      if (c.id == id) {
        return c.copyWith(title: trimmed);
      }
      return c;
    }).toList();

    state = state.copyWith(conversations: updatedList);
    await _cache.saveConversations(updatedList);

    try {
      await _repo.updateConversation(id, title: trimmed);
    } catch (e) {
      debugPrint('CONV: Failed to update title remotely: $e');
      // Revert if failed
      final reverted = state.conversations.map((c) {
        if (c.id == id) {
          return c.copyWith(title: oldConv.title);
        }
        return c;
      }).toList();
      state = state.copyWith(conversations: reverted);
      await _cache.saveConversations(reverted);
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
