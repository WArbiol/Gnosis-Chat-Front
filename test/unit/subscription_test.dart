import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';

void main() {
  group('PlanEntity and PlanType Tests', () {
    test('free plan should have correct default values', () {
      final plan = PlanType.free.entity;
      expect(plan.type, equals(PlanType.free));
      expect(plan.displayName, equals('Gratuito'));
      expect(plan.priceMonthly, equals(0.0));
      expect(plan.questionLimit, equals(3));
      expect(plan.chamberLevel, equals(1));
    });

    test('basic plan should have correct default values and price', () {
      final plan = PlanType.basic.entity;
      expect(plan.type, equals(PlanType.basic));
      expect(plan.displayName, equals('Básico'));
      expect(plan.priceMonthly, equals(9.99));
      expect(plan.questionLimit, equals(100));
      expect(plan.chamberLevel, equals(1));
    });

    test('premium plan should have correct default values and price', () {
      final plan = PlanType.premium.entity;
      expect(plan.type, equals(PlanType.premium));
      expect(plan.displayName, equals('Premium'));
      expect(plan.priceMonthly, equals(29.99));
      expect(plan.questionLimit, equals(1000));
      expect(plan.chamberLevel, equals(1));
    });

    test('plan serialization and deserialization', () {
      final original = PlanType.basic.entity;
      final json = original.toJson();
      expect(json['type'], equals('basic'));
      expect(json['priceMonthly'], equals(9.99));
      expect(json['questionLimit'], equals(100));

      final deserialized = PlanEntity.fromJson(json);
      expect(deserialized, equals(original));
    });
  });
}
