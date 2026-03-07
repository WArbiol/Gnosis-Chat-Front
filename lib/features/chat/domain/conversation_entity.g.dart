// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationEntityImpl _$$ConversationEntityImplFromJson(
  Map<String, dynamic> json,
) => _$ConversationEntityImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => MessageEntity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
  lastMessagePreview: json['lastMessagePreview'] as String?,
);

Map<String, dynamic> _$$ConversationEntityImplToJson(
  _$ConversationEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'messages': instance.messages,
  'messageCount': instance.messageCount,
  'lastMessagePreview': instance.lastMessagePreview,
};
