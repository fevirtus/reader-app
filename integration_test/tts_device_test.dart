// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reader_app/core/models/chapter_model.dart';
import 'package:reader_app/core/repositories/chapters_repository.dart';
import 'package:reader_app/core/storage/database/app_database.dart';

const media = MethodChannel('reader_app/tts_media');
Future<Map<dynamic, dynamic>> snapshot() async =>
    Map<dynamic, dynamic>.from(await media.invokeMethod('getSnapshot'));
Future<Map<dynamic, dynamic>> until(
  bool Function(Map<dynamic, dynamic>) matches, {
  int seconds = 25,
}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    final state = await snapshot();
    if (matches(state)) return state;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('TTS timeout: ${await snapshot()}');
}

Future<void> start(
  String id,
  String? next,
  String origin, {
  String content = 'Xin chào.',
}) => media.invokeMethod('startReading', {
  'content': content,
  'contentKey': id,
  'nextChapterId': next,
  'apiBaseUrl': origin,
  'speed': 0.9,
  'language': 'vi-VN',
  'includeTitle': false,
  'backgroundModeEnabled': true,
});

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native TTS reads local chapters and respects playback commands',
    (tester) async {
      final package = await media.invokeMethod<String>('getApplicationId');
      if (package != 'dev.fevirtus.reader.test') {
        throw StateError('Use READER_DEVICE_TEST=1: device tests require the isolated test package.');
      }
      final db = AppDatabase();
      final repo = ChaptersRepository(db);
      const novelId = '__tts_device_regression__';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final origin = 'http://127.0.0.1:${server.port}';
      var requests = 0;
      var hang = false;
      final pending = <HttpRequest>[];
      final hangingRequestArrived = Completer<void>();
      server.listen((request) async {
        requests++;
        if (hang) {
          pending.add(request);
          if (!hangingRequestArrived.isCompleted) {
            hangingRequestArrived.complete();
          }
          return;
        }
        request.response.statusCode = 503;
        await request.response.close();
      });
      try {
        await repo.saveDownloadedChapter(
          ChapterModel(
            id: '__tts_local_next__',
            novelId: novelId,
            number: 2,
            title: 'Kiểm tra',
            content: 'Đây là chương lưu trên máy. ' * 30,
            createdAt: DateTime.now(),
          ),
        );
        await media.invokeMethod('initialize', {'backgroundModeEnabled': true});
        await until(
          (s) => (s['availableVietnameseVoices'] as List? ?? []).isNotEmpty,
        );
        await start('__tts_first__', '__tts_local_next__', origin);
        await until(
          (s) =>
              s['contentKey'] == '__tts_local_next__' &&
              s['activeParagraphIndex'] != -1,
        );
        expect(
          requests,
          0,
          reason: 'Downloaded next chapter must never call API',
        );
        await media.invokeMethod('pause');
        final paused = await until((s) => s['status'] == 'paused');
        await Future<void>.delayed(const Duration(seconds: 1));
        expect((await snapshot())['paragraphIndex'], paused['paragraphIndex']);
        await media.invokeMethod('resume');
        await until(
          (s) => s['status'] == 'playing' && s['activeParagraphIndex'] != -1,
        );
        await media.invokeMethod('skipForward');
        await until(
          (s) =>
              (s['paragraphIndex'] as int) > (paused['paragraphIndex'] as int),
        );
        final beforeBackground = await snapshot();
        print('BACKGROUND_TEST_READY');
        await Future<void>.delayed(const Duration(seconds: 8));
        final afterBackground = await snapshot();
        expect(afterBackground['status'], 'playing');
        expect(
          afterBackground['paragraphIndex'],
          greaterThan(beforeBackground['paragraphIndex'] as int),
        );
        print('PASS playback advances with activity in background');
        print('BACKGROUND_TEST_DONE');
        await Future<void>.delayed(const Duration(seconds: 3));
        await media.invokeMethod('stop');
        await until((s) => s['status'] == 'idle' && s['contentKey'] == null);
        print('PASS local transition / pause / resume / skip / stop');

        await start('__tts_network_failure__', '__tts_missing__', origin);
        await until(
          (s) => s['status'] == 'paused' && s['errorMessage'] != null,
        );
        expect(requests, 1, reason: 'No automatic retry storm');
        await media.invokeMethod('resume');
        await until(
          (s) => s['status'] == 'paused' && s['errorMessage'] != null,
        );
        expect(requests, 2, reason: 'Resume retries missing chapter');
        print('PASS failed next chapter pauses with explicit retry');

        hang = true;
        await media.invokeMethod('resume');
        await until((s) => s['isPreparingNextChapter'] == true);
        await hangingRequestArrived.future.timeout(const Duration(seconds: 5));
        await media.invokeMethod('stop');
        await until((s) => s['status'] == 'idle');
        for (final request in pending) {
          request.response.statusCode = 503;
          await request.response.close();
        }
        await Future<void>.delayed(const Duration(seconds: 2));
        expect((await snapshot())['status'], 'idle');
        expect((await snapshot())['contentKey'], isNull);
        print('PASS stop while loading cannot restart stale playback');
      } finally {
        await media.invokeMethod('stop');
        await server.close(force: true);
        await repo.deleteNovelChapters(novelId);
        await db.close();
      }
    },
  );
}
