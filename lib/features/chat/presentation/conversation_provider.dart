import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/chat/domain/conversation_entity.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
      return ConversationNotifier(ref);
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
  ConversationNotifier(this._ref) : super(const ConversationState());

  final Ref _ref;

  /// Creates a new empty conversation and activates it.
  void createConversation() {
    final now = DateTime.now();
    final conv = ConversationEntity(
      id: _uuid.v4(),
      title: 'Nova conversa',
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      conversations: [conv, ...state.conversations],
      activeId: () => conv.id,
    );

    _ref.read(chatProvider.notifier).clearHistory();
  }

  /// Selects an existing conversation and loads its messages.
  void selectConversation(String id) {
    final conv = state.conversations.where((c) => c.id == id).firstOrNull;
    if (conv == null) return;

    state = state.copyWith(activeId: () => id);
    _ref.read(chatProvider.notifier).loadMessages(conv.messages);
  }

  /// Deletes a conversation. If it was active, clears the chat.
  void deleteConversation(String id) {
    final wasActive = state.activeId == id;
    final updated = state.conversations.where((c) => c.id != id).toList();

    state = state.copyWith(
      conversations: updated,
      activeId: wasActive ? () => null : null,
    );

    if (wasActive) {
      _ref.read(chatProvider.notifier).clearHistory();
    }
  }

  /// Updates the active conversation with the current chat messages.
  /// Called after each message to keep conversations in sync.
  void syncMessages(List<MessageEntity> messages) {
    if (state.activeId == null) return;

    final updated = state.conversations.map((c) {
      if (c.id != state.activeId) return c;

      final title = messages.isNotEmpty
          ? _truncate(messages.first.content, 40)
          : 'Nova conversa';

      return c.copyWith(
        messages: messages,
        title: title,
        updatedAt: DateTime.now(),
      );
    }).toList();

    state = state.copyWith(conversations: updated);
  }

  /// Searches conversations by title (case-insensitive).
  List<ConversationEntity> search(String query) {
    if (query.isEmpty) return state.conversations;
    final lower = query.toLowerCase();
    return state.conversations
        .where((c) => c.title.toLowerCase().contains(lower))
        .toList();
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }
}
