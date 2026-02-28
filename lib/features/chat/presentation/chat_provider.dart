import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/chat/data/chat_remote_source.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/services/api/api_client.dart';
import 'package:uuid/uuid.dart';

final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<MessageEntity>>>(
  (ref) {
    final api = ref.watch(apiClientProvider);
    return ChatNotifier(ChatRemoteSource(api));
  },
);

const _uuid = Uuid();

class ChatNotifier extends StateNotifier<AsyncValue<List<MessageEntity>>> {
  ChatNotifier(this._repo) : super(const AsyncValue.data([]));

  final ChatRemoteSource _repo;

  Future<void> ask(String query) async {
    final userMsg = MessageEntity(
      id: _uuid.v4(),
      content: query,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    // Add user message immediately
    state = AsyncValue.data([...state.valueOrNull ?? [], userMsg]);

    try {
      final result = await _repo.ask(query);
      final assistantMsg = MessageEntity(
        id: _uuid.v4(),
        content: result.answer,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        citations: result.citations,
        route: result.route,
      );
      state = AsyncValue.data([...state.valueOrNull ?? [], assistantMsg]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clearHistory() => state = const AsyncValue.data([]);
}
