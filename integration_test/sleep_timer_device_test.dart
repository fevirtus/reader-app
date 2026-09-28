// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reader_app/core/audio/sleep_timer.dart';
import 'tts_device_test.dart' as tts;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'sleep deadline pauses TTS in background without losing position',
    (tester) async {
      expect(
        await tts.media.invokeMethod<String>('getApplicationId'),
        'dev.fevirtus.reader.test',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Sleep timer verification')),
        ),
      );
      await tts.media.invokeMethod('initialize', {
        'backgroundModeEnabled': true,
      });
      await tts.until(
        (s) => (s['availableVietnameseVoices'] as List? ?? []).isNotEmpty,
      );
      await tts.start(
        'sleep-tts',
        null,
        '',
        content: 'Đây là đoạn kiểm tra hẹn giờ tắt và giữ vị trí nghe. ' * 50,
      );
      await tts.until((s) => s['status'] == 'playing');
      // Native fallback must work without creating the Dart timer provider.
      await SleepTimer.channel.invokeMethod<void>('set', {
        'milliseconds': 2000,
      });
      print('BACKGROUND_TEST_READY');
      await Future<void>.delayed(const Duration(seconds: 6));
      final state = await tts.snapshot();
      expect(state['status'], 'paused');
      expect(state['contentKey'], 'sleep-tts');
      print('BACKGROUND_TEST_DONE');
      await Future<void>.delayed(const Duration(seconds: 2));
      await tts.media.invokeMethod('stop');
    },
  );
}
