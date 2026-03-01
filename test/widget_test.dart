import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gnosis_chat/app.dart';

void main() {
  testWidgets('GnosisApp renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GnosisApp()));

    expect(find.text('Gnosis'), findsOneWidget);
  });
}
