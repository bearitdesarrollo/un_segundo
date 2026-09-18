import 'package:flutter_test/flutter_test.dart';
import 'package:un_segundo/app.dart';

void main() {
  testWidgets('App loads splash', (WidgetTester tester) async {
    await tester.pumpWidget(const UnSegundoApp());
    expect(find.text('1 SEGUNDO'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
  });
}
