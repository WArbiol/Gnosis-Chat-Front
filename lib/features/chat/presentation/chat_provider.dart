import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/chat/data/conversation_remote_source.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/conversation_provider.dart';
import 'package:uuid/uuid.dart';

final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<MessageEntity>>>((ref) {
      final repo = ref.watch(conversationRemoteSourceProvider);
      return ChatNotifier(repo, ref);
    });

/// Tracks whether the AI is currently generating a response.
final isLoadingProvider = StateProvider<bool>((ref) => false);

const _uuid = Uuid();

class ChatNotifier extends StateNotifier<AsyncValue<List<MessageEntity>>> {
  ChatNotifier(this._repo, this._ref) : super(const AsyncValue.data([]));

  final ConversationRemoteSource _repo;
  final Ref _ref;

  /// Reference to the provider ref, set externally.
  StateController<bool>? _loadingCtrl;

  void setLoadingController(StateController<bool> ctrl) {
    _loadingCtrl = ctrl;
  }

  Future<void> ask(String query) async {
    // Determine active conversation or create one if none exists
    final convNotifier = _ref.read(conversationProvider.notifier);
    var activeId = _ref.read(conversationProvider).activeId;

    debugPrint('CHAT: Starting query: $query');
    if (activeId == null) {
      debugPrint('CHAT: Creating new conversation...');
      await convNotifier.createConversation();
      activeId = _ref.read(conversationProvider).activeId;
      debugPrint('CHAT: Active ID: $activeId');
      if (activeId == null) return; // creation failed
    }

    // 1. Optimistic UI update for user message
    final userMsg = MessageEntity(
      id: _uuid.v4(),
      content: query,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final currentMessages = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentMessages, userMsg]);
    convNotifier.syncMessages([...currentMessages, userMsg]);

    _loadingCtrl?.state = true;

    try {
      // 2. Network call to /ask (persists both user and AI message)
      debugPrint('CHAT: Sending message...');
      final aiMessage = await _repo.sendMessage(activeId, query);
      debugPrint('CHAT: SUCCESS.');

      // 3. Update UI with the full AI response
      final nextMessages = [...currentMessages, userMsg, aiMessage];
      state = AsyncValue.data(nextMessages);
      convNotifier.syncMessages(nextMessages);
    } catch (e, stack) {
      debugPrint('CHAT: Error sending message: $e');
      debugPrint('$stack');
    } finally {
      // Hide typing indicator
      _loadingCtrl?.state = false;
    }
  }

  void clearHistory() => state = const AsyncValue.data([]);

  void loadMessages(List<MessageEntity> messages) =>
      state = AsyncValue.data(List.of(messages));
}
