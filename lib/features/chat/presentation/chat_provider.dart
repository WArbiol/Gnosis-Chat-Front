import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/chat/data/chat_remote_source.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/services/api/api_client.dart';
import 'package:uuid/uuid.dart';

final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<MessageEntity>>>((ref) {
      final api = ref.watch(apiClientProvider);
      return ChatNotifier(ChatRemoteSource(api));
    });

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

    // --- MOCK: simulate word-by-word streaming ---
    // TODO: replace with real WebSocket/API call via _repo.ask(query)
    const mockResponse = 'Esta mensagem é apenas um mock';
    final words = mockResponse.split(' ');
    final assistantId = _uuid.v4();
    var accumulated = '';

    for (final word in words) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      accumulated = accumulated.isEmpty ? word : '$accumulated $word';

      final assistantMsg = MessageEntity(
        id: assistantId,
        content: accumulated,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      final messages = <MessageEntity>[...state.valueOrNull ?? []];
      // Replace or append: if last message is this assistant, replace it
      if (messages.isNotEmpty && messages.last.id == assistantId) {
        messages[messages.length - 1] = assistantMsg;
      } else {
        messages.add(assistantMsg);
      }
      state = AsyncValue.data(messages);
    }
    // --- END MOCK ---
  }

  void clearHistory() => state = const AsyncValue.data([]);
}
