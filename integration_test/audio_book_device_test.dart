import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Audio book streams, seeks, pauses and plays cached audio offline',
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
      server.listen((request) {
        request.response.headers.contentType = ContentType('audio', 'wav');
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        request.response.close();
      });
      final player = AudioPlayer();
      final file = File(
        '${(await getTemporaryDirectory()).path}/audiobook-device.wav',
      );
      try {
        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse('http://127.0.0.1:${server.port}/chapter.wav'),
            tag: const MediaItem(id: 'test-stream', title: 'Audio book stream'),
          ),
        );
        player.play();
        await tester.pump(const Duration(seconds: 1));
        expect(player.duration!.inSeconds, 4);
        expect(player.position.inMilliseconds, greaterThan(0));
        await player.pause();
        expect(player.playing, false);
        await player.seek(const Duration(seconds: 2));
        expect(player.position.inMilliseconds, greaterThanOrEqualTo(1900));
        await player.setSpeed(1.5);
        expect(player.speed, 1.5);
        await player.stop();
        await file.writeAsBytes(bytes, flush: true);
        await server.close(force: true);
        await player.setAudioSource(
          AudioSource.uri(
            file.uri,
            tag: const MediaItem(
              id: 'test-offline',
              title: 'Audio book offline',
            ),
          ),
        );
        player.play();
        await tester.pump(const Duration(seconds: 1));
        expect(player.playing, true);
        expect(player.position.inMilliseconds, greaterThan(0));
        await player.pause();
      } finally {
        await player.dispose();
        await server.close(force: true);
        if (await file.exists()) await file.delete();
      }
    },
  );
}
