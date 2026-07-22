// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageEntityImpl _$$MessageEntityImplFromJson(Map<String, dynamic> json) =>
    _$MessageEntityImpl(
      id: json['id'] as String,
      content: json['content'] as String,
      role: $enumDecode(_$MessageRoleEnumMap, json['role']),
      timestamp: DateTime.parse(json['created_at'] as String),
      citations:
          (json['citations'] as List<dynamic>?)
              ?.map((e) => CitationEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      suggestedFollowups:
          (json['suggested_followups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      route: json['route'] as String? ?? '',
    );

Map<String, dynamic> _$$MessageEntityImplToJson(_$MessageEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'created_at': instance.timestamp.toIso8601String(),
      'citations': instance.citations,
      'suggested_followups': instance.suggestedFollowups,
      'route': instance.route,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
};

_$CitationEntityImpl _$$CitationEntityImplFromJson(Map<String, dynamic> json) =>
    _$CitationEntityImpl(
      pdfName: json['pdf_name'] as String,
      page: (json['page'] as num).toInt(),
      snippet: json['snippet'] as String? ?? '',
    );

Map<String, dynamic> _$$CitationEntityImplToJson(
  _$CitationEntityImpl instance,
) => <String, dynamic>{
  'pdf_name': instance.pdfName,
  'page': instance.page,
  'snippet': instance.snippet,
};
