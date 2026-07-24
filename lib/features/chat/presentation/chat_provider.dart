import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/chat/data/conversation_remote_source.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/conversation_provider.dart';
import 'package:uuid/uuid.dart';

class ActiveFilters {
  const ActiveFilters({
    this.books = const [],
    this.authors = const [],
    this.chamberLevels = const [1, 2],
  });

  final List<String> books;
  final List<String> authors;
  final List<int> chamberLevels;

  bool get isEmpty => books.isEmpty && authors.isEmpty && chamberLevels.length == 2;

  ActiveFilters copyWith({
    List<String>? books,
    List<String>? authors,
    List<int>? chamberLevels,
  }) {
    return ActiveFilters(
      books: books ?? this.books,
      authors: authors ?? this.authors,
      chamberLevels: chamberLevels ?? this.chamberLevels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (books.isNotEmpty) 'books': books,
      if (authors.isNotEmpty) 'authors': authors,
      'chamber_levels': chamberLevels,
    };
  }
}

final activeFiltersProvider = StateProvider<ActiveFilters>((ref) => const ActiveFilters());

final pdfCatalogProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(conversationRemoteSourceProvider);
  return repo.getPdfCatalog();
});

final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<MessageEntity>>>((ref) {
      final repo = ref.watch(conversationRemoteSourceProvider);
      return ChatNotifier(repo, ref);
    });

/// Tracks which conversation ID is currently generating an AI response (null if none).
final loadingConversationIdProvider = StateProvider<String?>((ref) => null);

/// Tracks the current agent status message displayed during loading.
final agentStatusProvider = StateProvider<String?>((ref) => null);

const _uuid = Uuid();

class ChatNotifier extends StateNotifier<AsyncValue<List<MessageEntity>>> {
  ChatNotifier(this._repo, this._ref) : super(const AsyncValue.data([]));

  final ConversationRemoteSource _repo;
  final Ref _ref;

  void cancelActiveStream() {
    _repo.cancelActiveStream();
  }

  Future<void> ask(String query) async {
    // 1. Optimistic UI update for user message IMMEDIATELY
    final userMsg = MessageEntity(
      id: _uuid.v4(),
      content: query,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final currentMessages = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentMessages, userMsg]);

    final convNotifier = _ref.read(conversationProvider.notifier);
    var activeId = _ref.read(conversationProvider).activeId;

    if (activeId != null) {
      convNotifier.syncMessages([...currentMessages, userMsg]);
      _ref.read(loadingConversationIdProvider.notifier).state = activeId;
    } else {
      _ref.read(loadingConversationIdProvider.notifier).state = 'NEW_CONV'; // Show loading while creating
    }

    _ref.read(agentStatusProvider.notifier).state = 'Compreendendo o propósito e o escopo...';

    try {
      if (activeId == null) {
        debugPrint('CHAT: Creating new conversation...');
        await convNotifier.createConversation();
        activeId = _ref.read(conversationProvider).activeId;
        debugPrint('CHAT: Active ID: $activeId');
        if (activeId == null) {
          state = AsyncValue.data(currentMessages);
          _ref.read(loadingConversationIdProvider.notifier).state = null;
          _ref.read(agentStatusProvider.notifier).state = null;
          return; // creation failed
        }
        convNotifier.syncMessages([...currentMessages, userMsg]);
        _ref.read(loadingConversationIdProvider.notifier).state = activeId;
      }
      // 2. Network call to /ask (persists both user and AI message)
      debugPrint('CHAT: Sending message...');
      final activeFilters = _ref.read(activeFiltersProvider);
      final uiFilters = activeFilters.isEmpty ? null : activeFilters.toJson();
      
      String streamingContent = '';
      final streamingMsgId = _uuid.v4();

      final aiMessage = await _repo.sendMessage(
        activeId,
        query,
        uiFilters: uiFilters,
        onStatusUpdate: (agent, msg) {
          _ref.read(agentStatusProvider.notifier).state = msg;
          if (agent == 'writer') {
            streamingContent = ''; // clear buffer if rewrites happen
          }
        },
        onToken: (tokenText) {
          streamingContent += tokenText;
          final currentActiveId = _ref.read(conversationProvider).activeId;
          if (currentActiveId == activeId) {
            final streamingMsg = MessageEntity(
              id: streamingMsgId,
              content: streamingContent,
              role: MessageRole.assistant,
              timestamp: DateTime.now(),
            );
            state = AsyncValue.data([...currentMessages, userMsg, streamingMsg]);
          }
        },
      );
      debugPrint('CHAT: SUCCESS.');

      // 3. Update UI only if the user hasn't switched conversations while waiting
      final nextMessages = [...currentMessages, userMsg, aiMessage];
      final currentActiveId = _ref.read(conversationProvider).activeId;
      if (currentActiveId == activeId) {
        state = AsyncValue.data(nextMessages);
      }
      convNotifier.syncMessagesForId(activeId, nextMessages);
    } catch (e, stack) {
      debugPrint('CHAT: Error sending message: $e');
      debugPrint('$stack');
      final currentActiveId = _ref.read(conversationProvider).activeId;
      if (currentActiveId == activeId) {
        state = AsyncValue.data(currentMessages);
      }
      if (activeId != null) {
        convNotifier.syncMessagesForId(activeId, currentMessages);
      }
      rethrow;
    } finally {
      // Clear typing indicator & status for this conversation
      final currentLoadingState = _ref.read(loadingConversationIdProvider);
      if (currentLoadingState == activeId || currentLoadingState == 'NEW_CONV') {
        _ref.read(loadingConversationIdProvider.notifier).state = null;
        _ref.read(agentStatusProvider.notifier).state = null;
      }
    }
  }

  void clearHistory() => state = const AsyncValue.data([]);

  void setLoadingState() => state = const AsyncValue.loading();

  void setErrorState(Object error, StackTrace stackTrace) =>
      state = AsyncValue.error(error, stackTrace);

  void loadMessages(List<MessageEntity> messages) {
    final isLoading = _ref.read(loadingConversationIdProvider) != null;
    if (isLoading) {
      return; // Do not overwrite optimistic loading state while generating response
    }
    final current = state.valueOrNull;
    if (current != null && _areMessageListsEqual(current, messages)) {
      return; // Skip duplicate state updates to prevent UI flicker
    }
    state = AsyncValue.data(List.of(messages));
  }

  bool _areMessageListsEqual(List<MessageEntity> a, List<MessageEntity> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].content != b[i].content ||
          a[i].role != b[i].role ||
          a[i].citations.length != b[i].citations.length) {
        return false;
      }
    }
    return true;
  }
}
