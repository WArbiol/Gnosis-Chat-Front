import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';
import 'package:gnosis_chat/features/subscription/presentation/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Path')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: PlanType.values
            .map((type) => _PlanCard(
                  plan: type.entity,
                  isLoading: planState.isLoading,
                  onSelect: () =>
                      ref.read(subscriptionProvider.notifier).checkout(type),
                ))
            .toList(),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isLoading,
    required this.onSelect,
  });

  final PlanEntity plan;
  final bool isLoading;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan.displayName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(
                  plan.priceMonthly == 0
                      ? 'Free'
                      : '\$${plan.priceMonthly.toStringAsFixed(2)}/mo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${plan.questionLimit} questions/month'),
            if (plan.interestLimit > 0)
              Text('${plan.interestLimit} interest memories'),
            if (plan.chamberLevel >= 2) const Text('✓ Segunda Câmara access'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : onSelect,
                child: Text('Select ${plan.displayName}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
