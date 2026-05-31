import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app/bookber_app.dart';

void main() {
  testWidgets('BookBer app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const BookBerApp());
    await tester.pumpAndSettle();
    expect(find.byType(BookBerApp), findsOneWidget);
  });
}
