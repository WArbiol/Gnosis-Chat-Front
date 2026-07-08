import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
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

  Future<MessageEntity> sendMessage(
    String conversationId,
    String query, {
    Map<String, dynamic>? uiFilters,
  }) async {
    final response = await _dio.post(
      'chat/ask',
      data: {
        'conversation_id': conversationId,
        'query': query,
        'ui_filters': uiFilters,
      },
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
    );

    final responseText = response.data as String;
    
    // Parse SSE to find the "final" event or "error" event
    final blocks = responseText.split('\n\n');
    Map<String, dynamic>? finalData;
    
    for (final block in blocks) {
      if (block.trim().isEmpty) continue;
      final lines = block.split('\n');
      String? eventType;
      String? dataContent;
      
      for (final line in lines) {
        if (line.startsWith('event:')) {
          eventType = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          dataContent = line.substring(5).trim();
        }
      }
      
      if (eventType == 'final' && dataContent != null) {
        finalData = jsonDecode(dataContent) as Map<String, dynamic>;
        break;
      }
      
      // If we got an error event
      if (eventType == 'error' && dataContent != null) {
        final errJson = jsonDecode(dataContent) as Map<String, dynamic>;
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: errJson['message'] ?? 'Erro no processamento do agente',
        );
      }
    }

    if (finalData == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Resposta final do agente não encontrada no stream.',
      );
    }

    final isHil = finalData['is_hil'] as bool? ?? false;
    var content = finalData['answer'] as String? ?? '';
    final recap = finalData['recap'] as String? ?? '';
    if (recap.isNotEmpty && !isHil) {
      content += '\n\n> $recap';
    }
    
    final citationsList = finalData['citations'] as List? ?? [];
    final citations = citationsList.map((e) {
      final map = e as Map<String, dynamic>;
      return CitationEntity(
        pdfName: map['pdf_name'] ?? map['book_name'] ?? 'N/A',
        page: map['page'] ?? 0,
        snippet: map['snippet'] ?? '',
      );
    }).toList();

    return MessageEntity(
      id: finalData['message_id'] ?? const Uuid().v4(),
      content: isHil ? 'PAUSE_HIL: $content' : content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      citations: citations,
      route: finalData['route'] ?? 'RAG',
    );
  }

  Future<List<Map<String, dynamic>>> getPdfCatalog() async {
    final response = await _dio.get('pdfs/catalog');
    final data = response.data as List;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
