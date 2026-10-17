import 'package:flutter_test/flutter_test.dart';
import 'package:demo_application/main.dart';

void main() {
  testWidgets('TodoApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());
    expect(find.text('TaskFlow'), findsOneWidget);
  });
}
