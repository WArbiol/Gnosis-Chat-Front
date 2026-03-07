import 'package:dio/dio.dart';
import 'package:gnosis_chat/features/chat/domain/conversation_entity.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';

class ConversationRemoteSource {
  ConversationRemoteSource(this._dio);

  final Dio _dio;

  Future<List<ConversationEntity>> listConversations({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get(
      'conversations',
      queryParameters: {'limit': limit, 'cursor': cursor},
    );

    final data = response.data['data'] as List;
    return data.map((e) => ConversationEntity.fromJson(e)).toList();
  }

  Future<ConversationEntity> createConversation(String title) async {
    final response = await _dio.post('conversations', data: {'title': title});
    return ConversationEntity.fromJson(response.data);
  }

  Future<ConversationEntity> getConversation(String id) async {
    final response = await _dio.get('conversations/$id');
    return ConversationEntity.fromJson(response.data);
  }

  Future<void> deleteConversation(String id) async {
    await _dio.delete('conversations/$id');
  }

  Future<ConversationEntity> updateConversation(String id, String title) async {
    final response = await _dio.patch(
      'conversations/$id',
      data: {'title': title},
    );
    return ConversationEntity.fromJson(response.data);
  }

  Future<MessageEntity> sendMessage(String conversationId, String query) async {
    final response = await _dio.post(
      'chat/ask',
      data: {'conversation_id': conversationId, 'query': query},
    );

    return MessageEntity.fromJson(response.data);
  }
}
