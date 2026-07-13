import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';
import 'package:gnosis_chat/services/api/api_client.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<PlanType>>(
      (ref) => SubscriptionNotifier(ref),
    );

class SubscriptionNotifier extends StateNotifier<AsyncValue<PlanType>> {
  SubscriptionNotifier(this._ref) : super(const AsyncValue.data(PlanType.free));

  final Ref _ref;

  /// Map PlanType → Stripe Price ID from .env
  String? _priceIdFor(PlanType plan) => switch (plan) {
    PlanType.free => null,
    PlanType.basic => dotenv.env['STRIPE_PRICE_BASIC'],
    PlanType.premium => dotenv.env['STRIPE_PRICE_PREMIUM'],
  };

  /// Create a Stripe Checkout Session and open it in the browser, or modify an existing subscription.
  Future<void> checkout(PlanType plan) async {
    final priceId = _priceIdFor(plan);
    if (priceId == null) return; // Free plan — no checkout needed

    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(apiClientProvider).dio;

      final response = await dio.post(
        'payments/checkout',
        data: {'price_id': priceId},
      );

      final status = response.data['status'] as String?;
      if (status == 'updated') {
        // Updated in-place, no redirect needed!
        await _ref.read(authProvider.notifier).fetchUser();
        state = AsyncValue.data(plan);
        return;
      }

      final checkoutUrl = response.data['checkout_url'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Checkout URL vazia retornada pelo servidor.');
      }

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
          webOnlyWindowName: kIsWeb ? '_self' : null,
        );
      } else {
        throw Exception('Não foi possível abrir o link de pagamento.');
      }

      state = AsyncValue.data(plan);
    } on DioException catch (e, st) {
      final errorMsg =
          e.response?.data?['message'] ?? e.message ?? e.toString();
      debugPrint('CHECKOUT ERROR: $errorMsg');
      state = AsyncValue.error(Exception(errorMsg), st);
    } catch (e, st) {
      debugPrint('CHECKOUT ERROR: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Open the Stripe Customer Portal for subscription management.
  Future<void> openCustomerPortal() async {
    try {
      final dio = _ref.read(apiClientProvider).dio;

      final response = await dio.post('payments/customer-portal');

      final portalUrl = response.data['portal_url'] as String?;
      if (portalUrl == null || portalUrl.isEmpty) {
        throw Exception('Portal URL vazia retornada pelo servidor.');
      }

      final uri = Uri.parse(portalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
          webOnlyWindowName: kIsWeb ? '_self' : null,
        );
      } else {
        throw Exception('Não foi possível abrir o portal de gerenciamento.');
      }
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['message'] ?? e.message ?? e.toString();
      debugPrint('CUSTOMER PORTAL ERROR: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('CUSTOMER PORTAL ERROR: $e');
      rethrow;
    }
  }

  /// Cancel the active Stripe subscription (downgrade to Free).
  Future<void> cancelSubscription() async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(apiClientProvider).dio;

      await dio.post('payments/cancel');
      await _ref.read(authProvider.notifier).fetchUser();

      state = const AsyncValue.data(PlanType.free);
    } on DioException catch (e, st) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? e.toString();
      debugPrint('CANCEL ERROR: $errorMsg');
      state = AsyncValue.error(Exception(errorMsg), st);
      rethrow;
    } catch (e, st) {
      debugPrint('CANCEL ERROR: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
