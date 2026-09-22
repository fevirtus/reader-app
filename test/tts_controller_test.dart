import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_app/features/reader/tts/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const media = MethodChannel('reader_app/tts_media');
  const events = MethodChannel('reader_app/tts_media_events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    messenger.setMockMethodCallHandler(events, (_) async => null);
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(media, null);
    messenger.setMockMethodCallHandler(events, null);
  });
  test('stop cancels a start waiting for engine initialization', () async {
    final initialized = Completer<void>();
    final calls = <String>[];
    messenger.setMockMethodCallHandler(media, (call) async {
      calls.add(call.method);
      if (call.method == 'initialize') await initialized.future;
      if (call.method == 'areNotificationsEnabled') return true;
      if (call.method == 'getSnapshot') return {'status': 'idle'};
      return null;
    });
    final controller = TtsNotifier(useNativeAndroid: true);
    final start = controller.startReading('Xin chào.', contentKey: 'old');
    await controller.stop();
    initialized.complete();
    await start;
    expect(calls, isNot(contains('startReading')));
    expect(controller.state.status, TtsStatus.idle);
    controller.dispose();
  });
  test(
    'Android start failure does not start a second playback engine',
    () async {
      messenger.setMockMethodCallHandler(media, (call) async {
        if (call.method == 'areNotificationsEnabled') return true;
        if (call.method == 'getSnapshot') return {'status': 'idle'};
        if (call.method == 'startReading') {
          throw PlatformException(code: 'tts_start_failed');
        }
        return null;
      });
      final controller = TtsNotifier(useNativeAndroid: true);
      await controller.startReading('Xin chào.', contentKey: 'chapter');
      expect(controller.state.status, TtsStatus.idle);
      expect(controller.state.errorMessage, isNotNull);
      await controller.stop();
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.pendingAutoStartChapterId, isNull);
      controller.dispose();
    },
  );
}
