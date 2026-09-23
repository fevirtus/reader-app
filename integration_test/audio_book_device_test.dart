import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reader_app/features/audiobook/audio_book_controller.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Audio book streams, advances, recovers at position and cancels retry',
    (tester) async {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'reader.audio_book.test',
        androidNotificationChannelName: 'Audio book test',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Audio book device verification')),
        ),
      );
      const rate = 24000, samples = rate * 4;
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

      try {
        await controller.play(book, chapters[0]);
        await waitUntil(() => player.position.inMilliseconds > 100);
        expect(player.duration!.inSeconds, 4);
        await controller.toggle();
        expect(player.playing, false);
        await player.seek(const Duration(seconds: 2));
        expect(player.position.inMilliseconds, greaterThanOrEqualTo(1900));
        await player.setSpeed(1.5);
        expect(player.speed, 1.5);
        await controller.toggle();
        await waitUntil(() => controller.chapter?['assetId'] == 'a2');
        await controller.stop();
        expect(controller.chapter, null);
        fail = true;
        await controller.play(
          book,
          chapters[0],
          position: const Duration(seconds: 2),
        );
        expect(controller.error, isNotNull);
        fail = false;
        await waitUntil(() => controller.error == null && player.playing);
        expect(player.position.inMilliseconds, greaterThanOrEqualTo(1900));
        await controller.stop();
        fail = true;
        await controller.play(book, chapters[0]);
        expect(controller.error, isNotNull);
        await controller.stop();
        final stoppedRequests = requests;
        fail = false;
        await tester.pump(const Duration(seconds: 6));
        expect(player.playing, false);
        expect(controller.chapter, null);
        expect(requests, stoppedRequests);
        final prefs = await SharedPreferences.getInstance();
        final progressBefore = prefs.getString(
          controller.key(controller.account, 'test-novel'),
        );
        final speedBefore = player.speed;
        final voice = <String, dynamic>{
          'id': 'sample',
          'name': 'Giọng thử',
          'previewUrl': url,
        };
        await controller.previewVoice(voice);
        await waitUntil(
          () => player.playing && player.position.inMilliseconds > 100,
        );
        expect(controller.edition, null);
        expect(controller.chapter, null);
        expect(player.speed, 1);
        expect(
          prefs.getString(controller.key(controller.account, 'test-novel')),
          progressBefore,
        );
        await controller.previewVoice(voice);
        expect(player.playing, false);
        expect(player.speed, speedBefore);
        final first = controller.previewVoice(voice);
        final second = controller.previewVoice({...voice, 'id': 'second'});
        await Future.wait([first, second]);
        expect(controller.previewVoiceId, 'second');
        await controller.stop();
      } finally {
        await controller.stop();
        container.dispose();
        await server.close(force: true);
      }
    },
  );
}
