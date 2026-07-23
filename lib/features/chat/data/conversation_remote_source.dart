import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:gnosis_chat/features/chat/domain/conversation_entity.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:http/http.dart' as http;
import 'package:gnosis_chat/services/api/streaming_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    void Function(String agent, String message)? onStatusUpdate,
    void Function(String token)? onToken,
  }) async {
    final baseUrl = _dio.options.baseUrl;
    final url = Uri.parse('${baseUrl}chat/ask');
    
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    
    final request = http.Request('POST', url);
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Content-Type'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.body = jsonEncode({
      'conversation_id': conversationId,
      'query': query,
      if (uiFilters != null) 'ui_filters': uiFilters,
    });

    final client = getStreamingHttpClient();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: RequestOptions(path: url.toString()),
        message: 'Falha ao se conectar com o servidor (Status: ${response.statusCode}).',
      );
    }

    String buffer = '';
    Map<String, dynamic>? finalData;

    final stringStream = response.stream.transform(utf8.decoder);

    await for (final chunk in stringStream) {
      buffer += chunk;
      while (buffer.contains('\n\n')) {
        final index = buffer.indexOf('\n\n');
        final block = buffer.substring(0, index);
        buffer = buffer.substring(index + 2);

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

        if (eventType == 'status' && dataContent != null) {
          try {
            final statusJson = jsonDecode(dataContent) as Map<String, dynamic>;
            final agent = statusJson['agent'] as String? ?? 'orchestrator';
            final msg = statusJson['message'] as String? ?? 'Processando...';
            debugPrint('SSE STATUS RECEIVED: $agent => $msg');
            onStatusUpdate?.call(agent, msg);
          } catch (e) {
            debugPrint('SSE STATUS ERROR: $e');
          }
        } else if (eventType == 'token' && dataContent != null) {
          try {
            final tokenJson = jsonDecode(dataContent) as Map<String, dynamic>;
            final tokenText = tokenJson['text'] as String? ?? '';
            if (tokenText.isNotEmpty) {
              onToken?.call(tokenText);
            }
          } catch (e) {
            debugPrint('SSE TOKEN ERROR: $e');
          }
        } else if (eventType == 'final' && dataContent != null) {
          finalData = jsonDecode(dataContent) as Map<String, dynamic>;
        } else if (eventType == 'error' && dataContent != null) {
          final errJson = jsonDecode(dataContent) as Map<String, dynamic>;
          throw DioException(
            requestOptions: RequestOptions(path: 'chat/ask'),
            message: errJson['message'] ?? 'Erro no processamento do agente',
          );
        }
      }
    }

    if (finalData == null) {
      throw DioException(
        requestOptions: RequestOptions(path: 'chat/ask'),
        message: 'Resposta final do agente não encontrada no stream.',
      );
    }

    final isHil = finalData['is_hil'] as bool? ?? false;
    var content = finalData['answer'] as String? ?? '';
    if (content.startsWith('PAUSE_HIL: ')) {
      content = content.replaceFirst('PAUSE_HIL: ', '');
    }

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

    final rawFollowups = finalData['suggested_followups'] as List? ?? [];
    final suggestedFollowups = rawFollowups.map((e) => e.toString()).toList();

    return MessageEntity(
      id: finalData['message_id'] ?? const Uuid().v4(),
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      citations: citations,
      suggestedFollowups: suggestedFollowups,
      route: finalData['route'] ?? (isHil ? 'ASK_USER' : 'RAG'),
    );
  }

  Future<List<Map<String, dynamic>>> getPdfCatalog() async {
    final response = await _dio.get('pdfs/catalog');
    final data = response.data as List;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
