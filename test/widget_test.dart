import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reader_app/app/app.dart';

void main() {
  testWidgets('Reader app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReaderApp()));

    expect(find.text('Reader App'), findsOneWidget);
  });
}
