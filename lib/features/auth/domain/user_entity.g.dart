// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserEntityImpl _$$UserEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserEntityImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      plan: json['plan'] as String? ?? 'free',
      chamberLevel: (json['chamberLevel'] as num?)?.toInt() ?? 1,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$UserEntityImplToJson(_$UserEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'plan': instance.plan,
      'chamberLevel': instance.chamberLevel,
      'questionCount': instance.questionCount,
    };
