import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/features/auth/domain/user_entity.dart';

void main() {
  group('UserEntity Tests', () {
    test('default values on fresh user creation', () {
      const user = UserEntity(
        id: 'usr-123',
        email: 'gnostico@gnosischat.com',
      );

      expect(user.id, equals('usr-123'));
      expect(user.email, equals('gnostico@gnosischat.com'));
      expect(user.plan, equals('free'));
      expect(user.chamberLevel, equals(1));
      expect(user.questionCount, equals(0));
      expect(user.subscriptionStatus, equals('free'));
      expect(user.subscriptionProvider, isNull);
      expect(user.currentPeriodEnd, isNull);
    });

    test('deserialization from Supabase JSON with active Stripe subscription', () {
      final json = {
        'id': 'usr-premium-456',
        'email': 'iniciado@gnosischat.com',
        'avatar_url': 'https://gnosischat.com/avatar.png',
        'plan': 'premium',
        'chamber_level': 1,
        'question_count': 42,
        'subscription_status': 'active',
        'subscription_provider': 'stripe',
        'current_period_end': '2026-09-14T23:59:59Z',
      };

      final user = UserEntity.fromJson(json);

      expect(user.id, equals('usr-premium-456'));
      expect(user.email, equals('iniciado@gnosischat.com'));
      expect(user.avatarUrl, equals('https://gnosischat.com/avatar.png'));
      expect(user.plan, equals('premium'));
      expect(user.questionCount, equals(42));
      expect(user.subscriptionStatus, equals('active'));
      expect(user.subscriptionProvider, equals('stripe'));
      expect(user.currentPeriodEnd, equals('2026-09-14T23:59:59Z'));
    });

    test('deserialization with canceled subscription status', () {
      final json = {
        'id': 'usr-canceled-789',
        'email': 'user@gnosischat.com',
        'plan': 'basic',
        'question_count': 15,
        'subscription_status': 'canceled',
        'subscription_provider': 'stripe',
        'current_period_end': '2026-08-30T12:00:00Z',
      };

      final user = UserEntity.fromJson(json);

      expect(user.plan, equals('basic'));
      expect(user.subscriptionStatus, equals('canceled'));
      expect(user.currentPeriodEnd, isNotNull);
    });
  });
}
