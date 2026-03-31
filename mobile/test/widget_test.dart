import 'package:flutter_test/flutter_test.dart';
import 'package:smartps/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartPSApp());
    await tester.pump();
    expect(find.text('SmartPS'), findsOneWidget);
  });
}
