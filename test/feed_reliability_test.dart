import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_app/core/connectivity/connectivity_service.dart';
import 'package:reader_app/core/models/chapter_model.dart';
import 'package:reader_app/core/network/api_client.dart';
import 'package:reader_app/core/network/providers.dart';
import 'package:reader_app/core/storage/database/app_database.dart';
import 'package:reader_app/features/home/providers/home_provider.dart';
import 'package:reader_app/features/novel/providers/novels_provider.dart';
import 'offline_sync_test.dart'
    show MemorySecrets, FakeHttp, jsonResponse, TestConnectivity;

void main() {
  test('overlapping home refreshes share one batch of requests', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final client = ApiClient(
      baseUrl: 'https://test.invalid',
      secureStore: MemorySecrets(),
    );
    final pending = <Completer<ResponseBody>>[];
    final started = Completer<void>();
    client.dio.httpClientAdapter = FakeHttp((_) {
      final response = Completer<ResponseBody>();
      pending.add(response);
      if (pending.length == 3) started.complete();
      return response.future;
    });
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(client),
        connectivityServiceProvider.overrideWithValue(TestConnectivity(false)),
      ],
    );
    addTearDown(() async {
      container.dispose();
      client.dio.close();
      await db.close();
    });
    final home = container.read(homeSyncProvider.notifier);
    final first = home.refresh();
    final second = home.refresh();
    await started.future;
    expect(pending.length, 3);
    for (final request in pending) {
      request.complete(jsonResponse({'items': []}));
    }
    await Future.wait([first, second]);
    expect(container.read(homeSyncProvider).hasError, isFalse);
  });

  test(
    'resume target is resolved only within the available chapter snapshot',
    () {
      final chapters = [
        ChapterListItem(
          id: 'local-a',
          number: 1,
          title: 'A',
          createdAt: DateTime(2026),
        ),
        ChapterListItem(
          id: 'local-b',
          number: 2,
          title: 'B',
          createdAt: DateTime(2026),
        ),
      ];
      expect(resolveReadingChapter(chapters, 'local-a', 2)?.id, 'local-a');
      expect(resolveReadingChapter(chapters, 'removed-id', 2)?.id, 'local-b');
      expect(
        resolveReadingChapter(chapters, 'unavailable-chapter', 100),
        isNull,
      );
      expect(resolveReadingChapter(chapters, null, null), isNull);
    },
  );
}
