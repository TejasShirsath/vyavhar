import 'package:flutter_test/flutter_test.dart';
import 'package:vyavhar/main.dart';

void main() {
  testWidgets('VyavharApp basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VyavharApp());
    await tester.pumpAndSettle();

    expect(find.text('Vyavhar'), findsOneWidget);
  });
}
