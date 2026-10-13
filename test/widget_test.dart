import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/app/pawquest_app.dart';

void main() {
  testWidgets('PawQuestApp loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PawQuestApp());
    expect(find.text('PAWQUEST'), findsOneWidget);
  });
}
