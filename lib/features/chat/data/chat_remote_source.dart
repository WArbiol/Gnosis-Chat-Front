import 'package:gnosis_chat/features/chat/data/chat_repository.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/services/api/api_client.dart';

class ChatRemoteSource implements ChatRepository {
  const ChatRemoteSource(this._api);

  final ApiClient _api;

  @override
  Future<({String answer, List<CitationEntity> citations, String route})> ask(
    String query,
  ) async {
    // TODO: POST /api/v1/chat/ask with {query}
    // final response = await _api.dio.post('/chat/ask', data: {'query': query});
    // return (
    //   answer: response.data['answer'],
    //   citations: (response.data['citations'] as List)
    //       .map((c) => CitationEntity.fromJson(c))
    //       .toList(),
    //   route: response.data['route'],
    // );
    throw UnimplementedError();
  }
}
