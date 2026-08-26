import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/about_gnosis_bottom_sheet.dart';

void main() {
  testWidgets('AboutGnosisBottomSheet renders title, 4 pillars and download buttons', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AboutGnosisBottomSheet(),
        ),
      ),
    );

    expect(find.text('Gnosis'), findsOneWidget);
    expect(find.text('As Quatro Chaves do Saber'), findsOneWidget);
    expect(find.text('Ciência'), findsOneWidget);
    expect(find.text('Arte'), findsOneWidget);
    expect(find.text('Filosofia'), findsOneWidget);
    expect(find.text('Religião'), findsOneWidget);
    expect(find.textContaining('gnosisbrasil.com'), findsOneWidget);
    // On native platforms (kIsWeb is false during unit tests), store buttons must not render
    expect(find.text('App Store'), findsNothing);
    expect(find.text('Google Play'), findsNothing);
  });
}
