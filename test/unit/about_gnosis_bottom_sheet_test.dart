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

    expect(find.text('O que é a Gnosis?'), findsOneWidget);
    expect(find.text('Os Quatro Pilares do Saber'), findsOneWidget);
    expect(find.text('Ciência'), findsOneWidget);
    expect(find.text('Arte'), findsOneWidget);
    expect(find.text('Filosofia'), findsOneWidget);
    expect(find.text('Religião (Religare)'), findsOneWidget);
    expect(find.text('gnosisbrasil.com'), findsOneWidget);
    expect(find.text('App Store'), findsOneWidget);
    expect(find.text('Google Play'), findsOneWidget);
  });
}
