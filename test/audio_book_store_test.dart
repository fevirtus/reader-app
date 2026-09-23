import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_app/features/audiobook/audio_book_store.dart';

class AudioAdapter implements HttpClientAdapter {
  List<int> data = utf8.encode('audio-one');
  bool broken = false;
  int calls = 0;
  String? range;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    range = options.headers['Range'] as String?;
    if (broken) return ResponseBody.fromString('unavailable', 503);
    final offset = range == null
        ? 0
        : int.parse(range!.split('=')[1].split('-')[0]);
    return ResponseBody.fromBytes(
      data.sublist(offset),
      offset > 0 ? 206 : 200,
      headers: {
        'content-range': ['bytes $offset-${data.length - 1}/${data.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory directory;
  late AudioAdapter adapter;
  late AudioBookStore store;
  AudioJson manifest(String revision, String asset, List<int> data) => {
    'id': 'edition',
    'novelId': 'novel',
    'title': 'Novel',
    'revision': revision,
    'chapters': [
      {
        'id': 'c1',
        'assetId': asset,
        'url': '/audio',
        'sha256': sha256.convert(data).toString(),
        'bytes': data.length,
      },
    ],
  };
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('audiobook-test');
    adapter = AudioAdapter();
    store = AudioBookStore(
      Dio(BaseOptions(baseUrl: 'https://test.invalid'))
        ..httpClientAdapter = adapter,
      directory: directory,
    );
  });
  tearDown(() async => directory.delete(recursive: true));
  test(
    'download verifies bytes and keeps previous snapshot on failed update',
    () async {
      await store.download(
        manifest('v1', 'a1', adapter.data),
        CancelToken(),
        (_, _) {},
      );
      expect((await store.saved()).single['revision'], 'v1');
      adapter.broken = true;
      await expectLater(
        store.download(
          manifest('v2', 'a2', adapter.data),
          CancelToken(),
          (_, _) {},
        ),
        throwsA(isA<DioException>()),
      );
      expect((await store.saved()).single['revision'], 'v1');
      expect(await (await store.audioFile('edition', 'a1')).exists(), true);
    },
  );
  test(
    'resume requests only the remainder and publishes a verified file',
    () async {
      final target = await store.audioFile('edition', 'a1');
      await target.parent.create(recursive: true);
      await File(
        '${target.path}.part',
      ).writeAsBytes(adapter.data.take(3).toList());
      await store.download(
        manifest('v1', 'a1', adapter.data),
        CancelToken(),
        (_, _) {},
      );
      expect(adapter.range, 'bytes=3-');
      expect(await target.readAsBytes(), adapter.data);
      final requests = adapter.calls;
      await store.download(
        manifest('v1', 'a1', adapter.data),
        CancelToken(),
        (_, _) {},
      );
      expect(adapter.calls, requests);
    },
  );
  test(
    'checksum failure never publishes and local delete preserves other voices',
    () async {
      await store.download(
        manifest('v1', 'a1', adapter.data),
        CancelToken(),
        (_, _) {},
      );
      await expectLater(
        store.download(
          manifest('v2', 'a2', utf8.encode('different')),
          CancelToken(),
          (_, _) {},
        ),
        throwsStateError,
      );
      expect((await store.saved()).single['revision'], 'v1');
      final other = manifest('v1', 'b1', adapter.data)..['id'] = 'other';
      await store.download(other, CancelToken(), (_, _) {});
      await store.delete('edition');
      expect((await store.saved()).single['id'], 'other');
    },
  );
}
