import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState renders logo and welcome texts', (
    WidgetTester tester,
  ) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    );
    final animation = Tween<double>(begin: 0.5, end: 1.0).animate(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EmptyState(glowAnim: animation)),
      ),
    );

    expect(find.text('Pergunte à Gnosis...'), findsOneWidget);
    expect(find.text('Conhecimento sagrado ao seu alcance'), findsOneWidget);

    controller.dispose();
  });
}
