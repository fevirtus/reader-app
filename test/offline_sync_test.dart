import 'package:reader_app/core/connectivity/connectivity_service.dart';
import 'package:reader_app/features/novel/providers/novels_provider.dart';
import 'package:reader_app/features/reader/providers/reader_provider.dart';
import 'package:reader_app/core/models/novel_model.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:reader_app/core/download/download_manager.dart';
import 'package:reader_app/core/repositories/downloads_repository.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reader_app/core/storage/database/app_database.dart';
import 'package:reader_app/core/storage/offline_store.dart';
import 'package:reader_app/core/storage/local_store.dart';
import 'package:reader_app/core/storage/secure_store.dart';
import 'package:reader_app/core/models/chapter_model.dart';
import 'package:reader_app/core/models/user_model.dart';
import 'package:reader_app/core/network/api_client.dart';
import 'package:reader_app/core/network/providers.dart';
import 'package:reader_app/core/repositories/chapters_repository.dart';
import 'package:reader_app/core/repositories/bookshelf_repository.dart';
import 'package:reader_app/core/repositories/novels_repository.dart';
import 'package:reader_app/core/sync/user_sync.dart';
import 'package:reader_app/features/auth/providers/auth_provider.dart';

class TestConnectivity extends ConnectivityService {
  TestConnectivity(this.online);
  final bool online;
  int checks = 0;
  @override
  Future<bool> checkIsOnline() async {
    checks++;
    return online;
  }
}

class MemorySecrets extends SecureStore {
  String? token = 'token-a';
  String? profile;
  @override
  Future<String?> getAccessToken() async => token;
  @override
  Future<void> setAccessToken(String value) async {
    token = value;
  }

  @override
  Future<String?> getProfile() async => profile;
  @override
  Future<void> setProfile(String value) async {
    profile = value;
  }

  @override
  Future<void> clear() async {
    token = null;
    profile = null;
  }
}

class FakeHttp implements HttpClientAdapter {
  FakeHttp(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
ChapterModel chapter(String id, String body, [int number = 1]) => ChapterModel(
  id: id,
  novelId: 'novel',
  number: number,
  title: 'Chapter $number',
  content: body,
  createdAt: DateTime.utc(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late OfflineStore store;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = OfflineStore(db);
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await db.close();
  });

  for (final online in [true, false]) {
    test(
      'downloaded detail, slug TOC and chapter make no API calls (online=$online)',
      () async {
        final novels = NovelsRepository(db);
        await novels.saveNovelDetail(
          NovelModel.fromJson({
            'id': 'novel',
            'slug': 'local-book',
            'title': 'Saved book',
          }),
        );
        await ChaptersRepository(
          db,
        ).saveDownloadedChapter(chapter('c1', 'saved text'));
        final connectivity = TestConnectivity(online);
        var requests = 0;
        final api = ApiClient(
          baseUrl: 'https://test.invalid',
          secureStore: MemorySecrets(),
        );
        api.dio.httpClientAdapter = FakeHttp((r) async {
          requests++;
          throw StateError('Downloaded books must not request the API');
        });
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            apiClientProvider.overrideWithValue(api),
            connectivityServiceProvider.overrideWithValue(connectivity),
          ],
        );
        addTearDown(container.dispose);
        expect(
          (await container.read(
            novelDetailProvider('local-book').future,
          )).title,
          'Saved book',
        );
        expect(
          (await container.read(
            chapterListProvider('local-book').future,
          )).single.id,
          'c1',
        );
        expect(
          (await container.read(chapterProvider('c1').future)).content,
          'saved text',
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(requests, 0);
        expect(connectivity.checks, 0);
      },
    );
  }

  test(
    'cached detail and TOC display before stalled API; failure keeps cache',
    () async {
      await NovelsRepository(db).saveNovelDetail(
        NovelModel.fromJson({
          'id': 'novel',
          'slug': 'local-book',
          'title': 'Cached book',
        }),
      );
      await ChaptersRepository(db).saveMeta('novel', [
        ChapterListItem(
          id: 'c1',
          number: 1,
          title: 'Chapter 1',
          createdAt: DateTime.utc(2026),
        ),
      ]);
      final gate = Completer<void>();
      final api = ApiClient(
        baseUrl: 'https://test.invalid',
        secureStore: MemorySecrets(),
      );
      api.dio.httpClientAdapter = FakeHttp((r) async {
        await gate.future;
        throw DioException(
          requestOptions: r,
          type: DioExceptionType.connectionError,
        );
      });
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiClientProvider.overrideWithValue(api),
          connectivityServiceProvider.overrideWithValue(TestConnectivity(true)),
        ],
      );
      addTearDown(container.dispose);
      expect(
        (await container
                .read(novelDetailProvider('novel').future)
                .timeout(const Duration(seconds: 2)))
            .title,
        'Cached book',
      );
      expect(
        (await container
                .read(chapterListProvider('novel').future)
                .timeout(const Duration(seconds: 2)))
            .single
            .id,
        'c1',
      );
      gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(container.read(novelDetailProvider('novel')).hasError, false);
      expect(container.read(chapterListProvider('novel')).hasError, false);
    },
  );

  test(
    'downloaded chapter cannot be silently overwritten by network cache',
    () async {
      final repo = ChaptersRepository(db);
      await repo.saveDownloadedChapter(chapter('c1', 'offline'));
      await repo.cacheViewedChapter(chapter('c1', 'edited on server'));
      expect((await repo.getDownloadedChapter('c1'))!.content, 'offline');
    },
  );

  test('failed snapshot replacement rolls back all chapters', () async {
    final repo = ChaptersRepository(db);
    await repo.saveDownloadedChapter(chapter('old', 'stable'));
    final meta = [
      {'id': 'new1', 'number': 1},
      {'id': 'new2', 'number': 2},
    ];
    await expectLater(
      repo.replaceDownloadFrom('novel', meta, (id) async {
        if (id == 'new2') throw StateError('download interrupted');
        return chapter(id, 'new');
      }),
      throwsStateError,
    );
    expect((await repo.cachedContentsList('novel')).map((c) => c.id), ['old']);
    expect(await repo.getCachedChapter('new1'), isNull);
  });

  test(
    'snapshot commit removes deleted chapters and rebuilds offline navigation',
    () async {
      final repo = ChaptersRepository(db);
      await repo.saveDownloadedChapter(chapter('deleted', 'old'));
      await repo.replaceDownloadFrom('novel', [
        {'id': 'one', 'number': 3},
        {'id': 'two', 'number': 7},
      ], (id) async => chapter(id, 'new', id == 'one' ? 3 : 7));
      expect(await repo.getCachedChapter('deleted'), isNull);
      expect((await repo.getDownloadedChapter('one'))!.nextChapterId, 'two');
      expect((await repo.getDownloadedChapter('two'))!.prevChapterNumber, 3);
      expect((await repo.cachedMeta('novel')).length, 2);
    },
  );

  test(
    'account snapshots and optimistic outbox edits remain isolated',
    () async {
      final repoA = BookshelfRepository(store, 'A', NovelsRepository(db));
      final repoB = BookshelfRepository(store, 'B', NovelsRepository(db));
      await repoA.saveServer([
        {'id': 'bm', 'novelId': 'novel', 'lastChapterNumber': 20},
      ]);
      await store.write('A', 'outbox:1', {
        'kind': 'progress',
        'novelId': 'novel',
        'chapterId': 'c30',
        'chapterNumber': 30,
        'occurredAt': '2026-01-01T00:00:00Z',
      });
      expect((await repoA.loadCached()).single.lastChapterNumber, 30);
      expect(await repoB.loadCached(), isEmpty);
      await repoA.saveServer([
        {'id': 'bm', 'novelId': 'novel', 'lastChapterNumber': 21},
      ]);
      expect((await repoA.loadCached()).single.lastChapterNumber, 30);
      await store.write('A', 'outbox:2', {
        'kind': 'remove',
        'novelId': 'novel',
        'occurredAt': '2026-01-02T00:00:00Z',
      });
      expect(await repoA.loadCached(), isEmpty);
    },
  );

  test(
    'scroll positions are account-scoped and concurrent writes stay consistent',
    () async {
      final a = LocalStore(owner: 'A');
      final b = LocalStore(owner: 'B');
      await Future.wait([
        a.saveProgress('novel', 'c1', 1, 12),
        a.saveProgress('novel', 'c2', 2, 45),
      ]);
      expect((await a.loadProgress('novel'))!['chapterId'], 'c2');
      expect((await a.loadProgress('novel'))!['scrollOffset'], 45);
      expect(await b.loadProgress('novel'), isNull);
    },
  );

  test('cold start without network preserves token and cached user', () async {
    final secrets = MemorySecrets()
      ..profile = jsonEncode({
        'token': 'token-a',
        'user': {'id': 'A', 'email': 'a@example.com'},
      });
    final api = ApiClient(
      baseUrl: 'https://test.invalid',
      secureStore: secrets,
    );
    api.dio.httpClientAdapter = FakeHttp(
      (r) async => throw DioException(
        requestOptions: r,
        type: DioExceptionType.connectionError,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        secureStoreProvider.overrideWithValue(secrets),
        apiClientProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.read(authProvider);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(container.read(authProvider), isA<AuthAuthenticated>());
    expect(secrets.token, 'token-a');
  });

  test('malformed profile response preserves cached offline session', () async {
    final secrets = MemorySecrets()
      ..profile = jsonEncode({
        'token': 'token-a',
        'user': {'id': 'A', 'email': 'a@example.com'},
      });
    final api = ApiClient(
      baseUrl: 'https://test.invalid',
      secureStore: secrets,
    );
    api.dio.httpClientAdapter = FakeHttp(
      (r) async => jsonResponse(['invalid']),
    );
    final container = ProviderContainer(
      overrides: [
        secureStoreProvider.overrideWithValue(secrets),
        apiClientProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.read(authProvider);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(container.read(authProvider), isA<AuthAuthenticated>());
    expect(secrets.token, 'token-a');
  });

  test('403 and stale-account 401 do not expire the current session', () async {
    final secrets = MemorySecrets();
    int expired = 0;
    final api = ApiClient(
      baseUrl: 'https://test.invalid',
      secureStore: secrets,
      onSessionExpired: () => expired++,
    );
    api.dio.httpClientAdapter = FakeHttp((r) async => jsonResponse({}, 403));
    await expectLater(
      api.dio.get('/api/user/profile'),
      throwsA(isA<DioException>()),
    );
    expect(expired, 0);
    api.dio.httpClientAdapter = FakeHttp((r) async {
      secrets.token = 'token-b';
      return jsonResponse({}, 401);
    });
    await expectLater(
      api.dio.get('/api/user/profile'),
      throwsA(isA<DioException>()),
    );
    expect(expired, 0);
    expect(secrets.token, 'token-b');
  });

  test(
    'outbox survives API failure, retries and requires exact acknowledgment',
    () async {
      final secrets = MemorySecrets();
      bool online = false;
      bool supportsSync = false;
      final api = ApiClient(
        baseUrl: 'https://test.invalid',
        secureStore: secrets,
      );
      api.dio.httpClientAdapter = FakeHttp((r) async {
        if (!online) {
          throw DioException(
            requestOptions: r,
            type: DioExceptionType.connectionError,
          );
        }
        return jsonResponse(
          supportsSync
              ? {
                  'acknowledgedEventId': r.data['eventId'],
                  'bookmark': {
                    'id': 'b',
                    'novelId': 'novel',
                    'lastChapterNumber': 30,
                  },
                }
              : {'status': 'ok'},
        );
      });
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          offlineStoreProvider.overrideWithValue(store),
          currentUserProvider.overrideWithValue(
            const UserModel(id: 'A', email: 'a@example.com'),
          ),
          secureStoreProvider.overrideWithValue(secrets),
          apiClientProvider.overrideWithValue(api),
        ],
      );
      final sync = container.read(userSyncProvider);
      await sync.enqueue('A', {
        'kind': 'progress',
        'novelId': 'novel',
        'chapterId': 'c30',
        'chapterNumber': 30,
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect((await store.entries('A', 'outbox:')).length, 1);
      online = true;
      await sync.flush();
      expect((await store.entries('A', 'outbox:')).length, 1);
      supportsSync = true;
      await sync.flush();
      expect(await store.entries('A', 'outbox:'), isEmpty);
      expect(
        (await store.read('A', 'bookshelf') as List)
            .single['lastChapterNumber'],
        30,
      );
      container.dispose();
    },
  );
  test(
    'interrupted update retains old snapshot and resumes only missing chapters',
    () async {
      final secrets = MemorySecrets();
      final chapters = ChaptersRepository(db);
      await chapters.saveDownloadedChapter(chapter('old', 'stable'));
      bool failSecond = true;
      int firstChapterRequests = 0;
      final manifest = {
        'revision': 'r1',
        'chapters': [
          for (final id in ['new1', 'new2'])
            {
              'id': id,
              'number': id == 'new1' ? 1 : 2,
              'title': id,
              'contentHash': sha256.convert(utf8.encode(id)).toString(),
            },
        ],
      };
      final api = ApiClient(
        baseUrl: 'https://test.invalid',
        secureStore: secrets,
      );
      api.dio.httpClientAdapter = FakeHttp((r) async {
        if (r.path.endsWith('download-manifest')) return jsonResponse(manifest);
        if (r.path == '/api/novels/novel') {
          return jsonResponse({
            'id': 'novel',
            'title': 'Novel',
            'slug': 'novel',
            'authorName': 'Author',
            'status': 'ONGOING',
            'totalChapters': 2,
          });
        }
        final id = r.path.split('/').last;
        if (id == 'new1') firstChapterRequests++;
        if (id == 'new2' && failSecond) {
          throw DioException(
            requestOptions: r,
            type: DioExceptionType.connectionError,
          );
        }
        return jsonResponse(chapter(id, id, id == 'new1' ? 1 : 2).toJson());
      });
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiClientProvider.overrideWithValue(api),
        ],
      );
      final manager = container.read(downloadManagerProvider);
      await manager.startDownload('novel');
      expect((await chapters.cachedContentsList('novel')).map((c) => c.id), [
        'old',
      ]);
      failSecond = false;
      await manager.startDownload('novel');
      expect(firstChapterRequests, 1);
      expect((await chapters.cachedContentsList('novel')).map((c) => c.id), [
        'new1',
        'new2',
      ]);
      final d = await container
          .read(downloadsRepositoryProvider)
          .watchForNovel('novel')
          .first;
      expect(d!.status, 'done');
      container.dispose();
    },
  );

  test(
    'delete waits for in-flight download and prevents resurrection',
    () async {
      final requested = Completer<void>();
      final response = Completer<ResponseBody>();
      final api = ApiClient(
        baseUrl: 'https://test.invalid',
        secureStore: MemorySecrets(),
      );
      api.dio.httpClientAdapter = FakeHttp((r) async {
        if (r.path.endsWith('download-manifest')) {
          return jsonResponse({
            'revision': 'r',
            'chapters': [
              {
                'id': 'c1',
                'number': 1,
                'title': 'c1',
                'contentHash': sha256.convert(utf8.encode('body')).toString(),
              },
            ],
          });
        }
        if (r.path == '/api/novels/novel') return jsonResponse({'id': 'novel'});
        requested.complete();
        return response.future;
      });
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          apiClientProvider.overrideWithValue(api),
        ],
      );
      final manager = container.read(downloadManagerProvider);
      final task = manager.startDownload('novel');
      await requested.future;
      final deletion = manager.deleteDownload('novel');
      response.complete(jsonResponse(chapter('c1', 'body').toJson()));
      await Future.wait([task, deletion]);
      expect(await ChaptersRepository(db).getCachedChapter('c1'), isNull);
      expect(
        await container
            .read(downloadsRepositoryProvider)
            .watchForNovel('novel')
            .first,
        isNull,
      );
      expect(await store.entries('download:novel', ''), isEmpty);
      container.dispose();
    },
  );
  test(
    'schema v1 upgrade preserves downloaded text and legacy records',
    () async {
      final dir = await Directory.systemTemp.createTemp('reader-migration-');
      final file = File('${dir.path}/reader.db');
      var legacy = AppDatabase(NativeDatabase(file));
      await ChaptersRepository(
        legacy,
      ).saveDownloadedChapter(chapter('kept', 'offline text'));
      await legacy.customStatement(
        "INSERT INTO bookmarks (id, novel_id, type, shelf_status) VALUES ('legacy', 'novel', 'reading', 'reading')",
      );
      await legacy.customStatement('DROP TABLE offline_store');
      await legacy.customStatement('PRAGMA user_version = 1');
      await legacy.close();
      final upgraded = AppDatabase(NativeDatabase(file));
      try {
        expect(
          (await ChaptersRepository(
            upgraded,
          ).getDownloadedChapter('kept'))!.content,
          'offline text',
        );
        expect((await upgraded.select(upgraded.bookmarks).get()).length, 1);
        final upgradedStore = OfflineStore(upgraded);
        await upgradedStore.write('A', 'outbox:pending', {'kind': 'progress'});
        expect(await upgradedStore.read('A', 'outbox:pending'), {
          'kind': 'progress',
        });
        final isolated = BookshelfRepository(
          upgradedStore,
          'B',
          NovelsRepository(upgraded),
        );
        expect(await isolated.loadCached(), isEmpty);
      } finally {
        await upgraded.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test('older novel response cannot overwrite newer metadata', () async {
    final repo = NovelsRepository(db);
    Map<String, dynamic> data(String title, String time) => {
      'id': 'novel',
      'title': title,
      'updatedAt': time,
    };
    await repo.saveNovelDetail(
      NovelModel.fromJson(data('new', '2026-02-01T00:00:00Z')),
    );
    await repo.saveNovelDetail(
      NovelModel.fromJson(data('old', '2026-01-01T00:00:00Z')),
    );
    expect((await repo.getCachedNovel('novel'))!.title, 'new');
  });
}
