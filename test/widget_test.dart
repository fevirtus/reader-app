import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reader_app/app/app.dart';

void main() {
  testWidgets('Reader app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReaderApp()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Trang chu'), findsOneWidget);
  });
}
