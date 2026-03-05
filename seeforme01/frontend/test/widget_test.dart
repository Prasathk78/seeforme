
import 'package:flutter_test/flutter_test.dart';
import 'package:seeforme01/main.dart'; // Correct import
void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SeeForMeApp()); // Correct class name
    expect(find.text('SeeForMe'), findsOneWidget);
  });
}
