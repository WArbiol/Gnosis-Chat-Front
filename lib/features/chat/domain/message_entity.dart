import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_entity.freezed.dart';
part 'message_entity.g.dart';

enum MessageRole { user, assistant }

@freezed
class MessageEntity with _$MessageEntity {
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
    modifiedJson['content'] = rawContent;
    modifiedJson['suggested_followups'] = followups;

    return _$MessageEntityFromJson(modifiedJson);
  }
}

@freezed
class CitationEntity with _$CitationEntity {
  const factory CitationEntity({
    @JsonKey(name: 'pdf_name') required String pdfName,
    required int page,
    @Default('') String snippet,
  }) = _CitationEntity;

  factory CitationEntity.fromJson(Map<String, dynamic> json) =>
      _$CitationEntityFromJson(json);
}
