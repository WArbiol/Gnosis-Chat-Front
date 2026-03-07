// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserEntityImpl _$$UserEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserEntityImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      plan: json['plan'] as String? ?? 'free',
      chamberLevel: (json['chamber_level'] as num?)?.toInt() ?? 1,
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$UserEntityImplToJson(_$UserEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'avatar_url': instance.avatarUrl,
      'plan': instance.plan,
      'chamber_level': instance.chamberLevel,
      'question_count': instance.questionCount,
    };
