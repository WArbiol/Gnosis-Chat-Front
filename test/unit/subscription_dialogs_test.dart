import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';
import 'package:gnosis_chat/features/subscription/presentation/widgets/subscription_change_dialog.dart';
import 'package:gnosis_chat/features/subscription/presentation/widgets/subscription_success_dialog.dart';

void main() {
  group('Subscription Dialogs Tests', () {
    testWidgets('SubscriptionChangeDialog renders upgrade content correctly', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await SubscriptionChangeDialog.show(
                      context,
                      currentPlan: 'basic',
                      targetPlan: PlanType.premium,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check contents
      expect(find.text('Fazer Upgrade para Premium?'), findsOneWidget);
      expect(find.text('R\$ 29,99/mês'), findsOneWidget);
      expect(find.text('1.000 perguntas/mês'), findsOneWidget);
      expect(find.text('Confirmar Upgrade'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Confirmar Upgrade'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('SubscriptionChangeDialog renders downgrade content and cancels correctly', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await SubscriptionChangeDialog.show(
                      context,
                      currentPlan: 'premium',
                      targetPlan: PlanType.basic,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check contents
      expect(find.text('Alterar para Plano Básico?'), findsOneWidget);
      expect(find.text('R\$ 9,99/mês'), findsOneWidget);
      expect(find.text('100 perguntas/mês'), findsOneWidget);
      expect(find.text('Confirmar Alteração'), findsOneWidget);

      // Tap Voltar (Cancel)
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('SubscriptionSuccessDialog renders basic and premium success states', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => SubscriptionSuccessDialog.show(context, 'basic'),
                  child: const Text('Show Success'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      expect(find.text('Plano Básico Ativado'), findsOneWidget);
      expect(find.text('Aproveitar Plano'), findsOneWidget);

      await tester.tap(find.text('Aproveitar Plano'));
      await tester.pumpAndSettle();

      expect(find.text('Plano Básico Ativado'), findsNothing);
    });
  });
}
