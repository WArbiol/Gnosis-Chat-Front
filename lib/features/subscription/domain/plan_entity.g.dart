// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlanEntityImpl _$$PlanEntityImplFromJson(Map<String, dynamic> json) =>
    _$PlanEntityImpl(
      type: $enumDecode(_$PlanTypeEnumMap, json['type']),
      displayName: json['displayName'] as String,
      priceMonthly: (json['priceMonthly'] as num).toDouble(),
      questionLimit: (json['questionLimit'] as num).toInt(),
      chamberLevel: (json['chamberLevel'] as num).toInt(),
    );

Map<String, dynamic> _$$PlanEntityImplToJson(_$PlanEntityImpl instance) =>
    <String, dynamic>{
      'type': _$PlanTypeEnumMap[instance.type]!,
      'displayName': instance.displayName,
      'priceMonthly': instance.priceMonthly,
      'questionLimit': instance.questionLimit,
      'chamberLevel': instance.chamberLevel,
    };

const _$PlanTypeEnumMap = {
  PlanType.free: 'free',
  PlanType.basic: 'basic',
  PlanType.premium: 'premium',
};
