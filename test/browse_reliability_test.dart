import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_app/core/network/api_client.dart';
import 'package:reader_app/core/network/providers.dart';
import 'package:reader_app/features/novel/providers/novels_provider.dart';
import 'offline_sync_test.dart' show MemorySecrets, FakeHttp, jsonResponse;

Map<String, dynamic> page(List<String> ids, {int number = 1}) => {
  'items': [
    for (final id in ids) {'id': id, 'title': id, 'slug': id},
  ],
  'currentPage': number,
  'totalPages': 3,
  'totalCount': 6,
};

class BrokenSecrets extends MemorySecrets {
  @override
  Future<String?> getAccessToken() =>
      Future.error(StateError('storage unavailable'));
}

void main() {
  test(
    'new searches cancel stale results and pagination cannot replace the new query',
    () async {
      final pending = <Completer<ResponseBody>>[];
      final started = StreamController<void>.broadcast();
      final client = ApiClient(
        baseUrl: 'https://test.invalid',
        secureStore: MemorySecrets(),
      );
      client.dio.httpClientAdapter = FakeHttp((options) {
        final response = Completer<ResponseBody>();
        pending.add(response);
        started.add(null);
        return response.future;
      });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(client)],
      );
      addTearDown(() {
        container.dispose();
        client.dio.close(force: true);
        started.close();
      });
      final notifier = container.read(novelsProvider.notifier);
      expect(
        pending,
        isEmpty,
      ); // no unfiltered request before the screen sets filters
      var next = started.stream.first;
      final old = notifier.updateParams(const BrowseParams(query: 'old'));
      await next;
      next = started.stream.first;
      final current = notifier.updateParams(
        const BrowseParams(query: 'current'),
      );
      await next;
      pending[1].complete(jsonResponse(page(['current'])));
      await current;
      pending[0].complete(jsonResponse(page(['old'])));
      await old;
      expect(
        container.read(novelsProvider).requireValue.items.single.id,
        'current',
      );
      next = started.stream.first;
      final more = notifier.loadNextPage();
      await next;
      next = started.stream.first;
      final newest = notifier.updateParams(const BrowseParams(query: 'newest'));
      await next;
      pending[3].complete(jsonResponse(page(['newest'])));
      await newest;
      pending[2].complete(jsonResponse(page(['stale-page'], number: 2)));
      await more;
      expect(
        container.read(novelsProvider).requireValue.items.single.id,
        'newest',
      );
    },
  );

  test(
    'pagination failure retains books, waits for retry and deduplicates results',
    () async {
      var calls = 0;
      final client = ApiClient(
        baseUrl: 'https://test.invalid',
        secureStore: MemorySecrets(),
      );
      client.dio.httpClientAdapter = FakeHttp((_) async {
        calls++;
        if (calls == 2) return jsonResponse({}, 503);
        return jsonResponse(
          calls == 1 ? page(['a']) : page(['a', 'b'], number: 2),
        );
      });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(client)],
      );
      addTearDown(() {
        container.dispose();
        client.dio.close();
      });
      final notifier = container.read(novelsProvider.notifier);
      await notifier.fetch();
      await notifier.loadNextPage();
      expect(container.read(novelsProvider).requireValue.items.single.id, 'a');
      expect(
        container.read(novelsProvider).requireValue.loadMoreFailed,
        isTrue,
      );
      await notifier.loadNextPage();
      expect(calls, 2);
      await notifier.loadNextPage(retry: true);
      expect(
        container.read(novelsProvider).requireValue.items.map((e) => e.id),
        ['a', 'b'],
      );
      expect(
        container.read(novelsProvider).requireValue.loadMoreFailed,
        isFalse,
      );
    },
  );

  test(
    'secure storage failure completes request with an error instead of hanging',
    () async {
      final client = ApiClient(
        baseUrl: 'https://test.invalid',
        secureStore: BrokenSecrets(),
      );
      addTearDown(() => client.dio.close());
      await expectLater(
        client.dio
            .get('/api/novels/browse')
            .timeout(const Duration(seconds: 2)),
        throwsA(isA<DioException>()),
      );
    },
  );
}
