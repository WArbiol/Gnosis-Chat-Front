import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<PlanType>>(
  (ref) => SubscriptionNotifier(),
);

class SubscriptionNotifier extends StateNotifier<AsyncValue<PlanType>> {
  SubscriptionNotifier() : super(const AsyncValue.data(PlanType.free));

  Future<void> checkout(PlanType plan) async {
    state = const AsyncValue.loading();
    try {
      // TODO: POST /api/v1/payments/checkout with price_id
      // TODO: open Stripe checkout URL via url_launcher
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
