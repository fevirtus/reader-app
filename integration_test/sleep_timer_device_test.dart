// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:reader_app/core/audio/sleep_timer.dart';
import 'package:reader_app/features/audiobook/audio_book_controller.dart';
import 'tts_device_test.dart' as tts;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'sleep deadline pauses TTS and audio in background without losing position',
    (tester) async {
      expect(
        await tts.media.invokeMethod<String>('getApplicationId'),
        'dev.fevirtus.reader.test',
      );
      await JustAudioBackground.init(
        androidNotificationChannelId: 'reader.sleep.test',
        androidNotificationChannelName: 'Sleep timer test',
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
      const rate = 24000, samples = rate * 20;
      final bytes = Uint8List(44 + samples * 2);
      final data = ByteData.sublistView(bytes);
      void chars(int offset, String value) =>
          bytes.setRange(offset, offset + value.length, value.codeUnits);
      chars(0, 'RIFF');
      data.setUint32(4, bytes.length - 8, Endian.little);
      chars(8, 'WAVE');
      chars(12, 'fmt ');
      data.setUint32(16, 16, Endian.little);
      data.setUint16(20, 1, Endian.little);
      data.setUint16(22, 1, Endian.little);
      data.setUint32(24, rate, Endian.little);
      data.setUint32(28, rate * 2, Endian.little);
      data.setUint16(32, 2, Endian.little);
      data.setUint16(34, 16, Endian.little);
      chars(36, 'data');
      data.setUint32(40, samples * 2, Endian.little);
      for (var i = 0; i < samples; i++) {
        data.setInt16(
          44 + i * 2,
          (sin(2 * pi * 440 * i / rate) * 800).round(),
          Endian.little,
        );
      }
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var fail = false;
      var requests = 0;
      server.listen((request) {
        requests++;
        if (fail) {
          request.response.statusCode = 503;
          request.response.close();
          return;
        }
        request.response.headers.contentType = ContentType('audio', 'wav');
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        request.response.close();
      });
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final controller = container.read(audioBookControllerProvider);
      final player = controller.player;
      final url = 'http://127.0.0.1:${server.port}/chapter.wav';
      final chapters = [
        {'id': 'c1', 'assetId': 'a1', 'number': 1, 'title': 'Một', 'url': url},
        {'id': 'c2', 'assetId': 'a2', 'number': 2, 'title': 'Hai', 'url': url},
      ];
      final book = <String, dynamic>{
        'id': 'test-edition',
        'novelId': 'test-novel',
        'title': 'Audio book test',
        'chapters': chapters,
      };
      Future<void> waitUntil(bool Function() predicate) async {
        for (var i = 0; i < 120 && !predicate(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(predicate(), true);
      }

      final sleep = container.read(sleepTimerProvider);
      try {
        await controller.play(book, chapters[0]);
        await waitUntil(
          () => player.playing && player.position.inMilliseconds > 100,
        );
        await sleep.set(const Duration(seconds: 2));
        print('BACKGROUND_TEST_READY');
        await Future<void>.delayed(const Duration(seconds: 6));
        expect(player.playing, false);
        expect(controller.chapter?['id'], 'c1');
        expect(player.position.inMilliseconds, greaterThan(100));
        expect(sleep.remaining, isNull);
        print('BACKGROUND_TEST_DONE');
        await Future<void>.delayed(const Duration(seconds: 2));
        final pausedAt = player.position;
        await controller.toggle();
        await waitUntil(() => player.playing);
        expect(player.position, greaterThanOrEqualTo(pausedAt));
        await controller.stop();
        fail = true;
        await controller.play(book, chapters[0]);
        expect(controller.error, isNotNull);
        await sleep.set(const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(seconds: 2));
        final stoppedRequests = requests;
        fail = false;
        await Future<void>.delayed(const Duration(seconds: 6));
        expect(player.playing, false);
        expect(
          requests,
          stoppedRequests,
          reason: 'Expiry must cancel network retries',
        );
      } finally {
        await sleep.set(null);
        await controller.stop();
        container.dispose();
        await server.close(force: true);
      }
    },
  );
}
