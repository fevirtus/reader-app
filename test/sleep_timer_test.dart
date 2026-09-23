import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reader_app/core/audio/sleep_timer_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_app/core/audio/sleep_timer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('compact timer sheet fits small screens, sets and cancels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timer = SleepTimer(nativeAndroid: false, onExpire: () async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sleepTimerProvider.overrideWith((ref) => timer)],
        child: const MaterialApp(
          home: Scaffold(body: SleepTimerButton(compact: true)),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Hẹn giờ tắt'));
    await tester.pumpAndSettle();
    expect(find.text('30 phút'), findsOneWidget);
    await tester.tap(find.text('30 phút'));
    await tester.pumpAndSettle();
    expect(timer.remaining, isNotNull);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ hẹn giờ'));
    await tester.pumpAndSettle();
    expect(timer.remaining, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test('expiry fires once, clears countdown and can be rearmed', () async {
    var calls = 0;
    final timer = SleepTimer(
      nativeAndroid: false,
      onExpire: () async {
        calls++;
      },
    );
    addTearDown(timer.dispose);
    await timer.set(const Duration(milliseconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(calls, 1);
    expect(timer.remaining, isNull);
    await timer.set(const Duration(milliseconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(calls, 2);
  });
  test('cancel and replacement do not fire an older deadline', () async {
    var calls = 0;
    final timer = SleepTimer(
      nativeAndroid: false,
      onExpire: () async {
        calls++;
      },
    );
    addTearDown(timer.dispose);
    await timer.set(const Duration(milliseconds: 30));
    await timer.set(const Duration(minutes: 10));
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(calls, 0);
    expect(timer.remaining!.inMinutes, 9);
    await timer.set(null);
    expect(timer.remaining, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(calls, 0);
  });
  test('native failure does not show a falsely armed timer', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      SleepTimer.channel,
      (_) async => throw PlatformException(code: 'failure'),
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(SleepTimer.channel, null),
    );
    final timer = SleepTimer(nativeAndroid: true, onExpire: () async {});
    addTearDown(timer.dispose);
    await expectLater(
      timer.set(const Duration(minutes: 15)),
      throwsA(isA<PlatformException>()),
    );
    expect(timer.remaining, isNull);
  });
}
