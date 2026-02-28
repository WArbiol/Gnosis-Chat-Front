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
      timestamp: DateTime.parse(json['timestamp'] as String),
      citations:
          (json['citations'] as List<dynamic>?)
              ?.map((e) => CitationEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      route: json['route'] as String? ?? '',
    );

Map<String, dynamic> _$$MessageEntityImplToJson(_$MessageEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'citations': instance.citations,
      'route': instance.route,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
};

_$CitationEntityImpl _$$CitationEntityImplFromJson(Map<String, dynamic> json) =>
    _$CitationEntityImpl(
      pdfName: json['pdfName'] as String,
      page: (json['page'] as num).toInt(),
      snippet: json['snippet'] as String? ?? '',
    );

Map<String, dynamic> _$$CitationEntityImplToJson(
  _$CitationEntityImpl instance,
) => <String, dynamic>{
  'pdfName': instance.pdfName,
  'page': instance.page,
  'snippet': instance.snippet,
};
