import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_entity.freezed.dart';
part 'plan_entity.g.dart';

enum PlanType { free, basic, premium }

@freezed
class PlanEntity with _$PlanEntity {
  const factory PlanEntity({
    required PlanType type,
    required String displayName,
    required double priceMonthly,
    required int questionLimit,
    required int chamberLevel,
  }) = _PlanEntity;

  factory PlanEntity.fromJson(Map<String, dynamic> json) =>
      _$PlanEntityFromJson(json);
}

extension PlanDefaults on PlanType {
  PlanEntity get entity => switch (this) {
    PlanType.free => const PlanEntity(
      type: PlanType.free,
      displayName: 'Gratuito',
      priceMonthly: 0,
      questionLimit: 3,
      chamberLevel: 1,
    ),
    PlanType.basic => const PlanEntity(
      type: PlanType.basic,
      displayName: 'Básico',
      priceMonthly: 9.99,
      questionLimit: 100,
      chamberLevel: 1,
    ),
    PlanType.premium => const PlanEntity(
      type: PlanType.premium,
      displayName: 'Premium',
      priceMonthly: 29.99,
      questionLimit: 1000,
      chamberLevel: 1,
    ),
  };
}
