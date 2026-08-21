import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gnosis_chat/core/utils/message_crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'message_entity.freezed.dart';
part 'message_entity.g.dart';

enum MessageRole { user, assistant }

@Freezed(toJson: false, fromJson: false)
class MessageEntity with _$MessageEntity {
  const MessageEntity._();

  const factory MessageEntity({
    required String id,
    required String content,
    required MessageRole role,
    @JsonKey(name: 'created_at') required DateTime timestamp,
    @Default([]) List<CitationEntity> citations,
    @JsonKey(name: 'suggested_followups') @Default([]) List<String> suggestedFollowups,
    @Default('') String route,
  }) = _MessageEntity;

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    var rawContent = json['content'] as String? ?? '';
    if (rawContent.startsWith('enc:v1:')) {
      try {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        rawContent = MessageCrypto.decryptContent(rawContent, currentUserId);
      } catch (_) {}
    }
    List<String> extractedFollowups = [];

    // Backwards compatibility for legacy HTML comment tags if present
    final regExp = RegExp(r'<!--followups:(.*?)-->', dotAll: true);
    final match = regExp.firstMatch(rawContent);
    if (match != null) {
      try {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          final list = jsonDecode(jsonStr) as List;
          extractedFollowups = list.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      rawContent = rawContent.replaceAll(regExp, '').trim();
    }

    final rawFollowups = json['suggested_followups'] as List? ?? [];
    final followups = rawFollowups.isNotEmpty
        ? rawFollowups.map((e) => e.toString()).toList()
        : extractedFollowups;

    final modifiedJson = Map<String, dynamic>.from(json);
    return MessageEntity(
      id: modifiedJson['id'] as String,
      content: rawContent,
      role: modifiedJson['role'] is MessageRole
          ? modifiedJson['role'] as MessageRole
          : MessageRole.values.byName(modifiedJson['role'] as String),
      timestamp: modifiedJson['created_at'] is DateTime
          ? modifiedJson['created_at'] as DateTime
          : DateTime.parse(modifiedJson['created_at'].toString()),
      citations: (modifiedJson['citations'] as List? ?? [])
          .map((e) => e is CitationEntity
              ? e
              : CitationEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestedFollowups: followups,
      route: modifiedJson['route'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role.name,
        'created_at': timestamp.toIso8601String(),
        'citations': citations
            .map((c) => {
                  'id': c.id,
                  'pdf_name': c.pdfName,
                  'page': c.page,
                  'snippet': c.snippet,
                })
            .toList(),
        'suggested_followups': suggestedFollowups,
        'route': route,
      };
}

@freezed
class CitationEntity with _$CitationEntity {
  const factory CitationEntity({
    @Default('') String id,
    @JsonKey(name: 'pdf_name') required String pdfName,
    required int page,
    @Default('') String snippet,
  }) = _CitationEntity;

  factory CitationEntity.fromJson(Map<String, dynamic> json) =>
      _$CitationEntityFromJson(json);
}
