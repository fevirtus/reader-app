import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

typedef AudioJson = Map<String, dynamic>;

/// Immutable files + atomic manifest replacement keep previous downloads usable.
class AudioBookStore {
  AudioBookStore(this.dio, {this.directory});
  final Dio dio;
  final Directory? directory;
  final Set<String> _busy = {};
  Future<Directory> root() async {
    final base =
        directory ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/audiobooks',
        );
    await base.create(recursive: true);
    return base;
  }

  String safe(String id) => sha256.convert(utf8.encode(id)).toString();
  Future<File> audioFile(String edition, String asset) async =>
      File('${(await root()).path}/${safe(edition)}/${safe(asset)}.m4a');
  Future<File> _manifest(String edition) async =>
      File('${(await root()).path}/${safe(edition)}/manifest.json');
  Future<List<AudioJson>> saved({String? novelId}) async {
    final list = <AudioJson>[];
    await for (final entry in (await root()).list()) {
      if (entry is! Directory) continue;
      final f = File('${entry.path}/manifest.json');
      try {
        if (await f.exists()) {
          final data = Map<String, dynamic>.from(
            jsonDecode(await f.readAsString()) as Map,
          );
          if (novelId == null || data['novelId'] == novelId) list.add(data);
        }
      } catch (_) {
        /* One corrupt manifest must not hide other downloads. */
      }
    }
    return list;
  }

  Future<void> download(
    AudioJson manifest,
    CancelToken cancel,
    void Function(int, int) progress,
  ) async {
    final edition = manifest['id'] as String;
    if (!_busy.add(edition)) throw StateError('Bản giọng đang được tải');
    try {
      final chapters = (manifest['chapters'] as List).cast<Map>();
      final ready = chapters.where((c) => c['assetId'] != null).toList();
      if (ready.isEmpty) throw StateError('Chưa có chương nào để tải');
      var done = 0;
      for (final c in ready) {
        if (cancel.isCancelled) throw StateError("Đã hủy tải");
        final file = await audioFile(edition, c['assetId'] as String);
        await file.parent.create(recursive: true);
        if (!await _valid(file, c)) {
          final partial = File('${file.path}.part');
          var offset = await partial.exists() ? await partial.length() : 0;
          if (offset >= (c['bytes'] as num).toInt()) {
            await partial.delete();
            offset = 0;
          }
          final response = await dio.get<ResponseBody>(
            c['url'] as String,
            cancelToken: cancel,
            options: Options(
              responseType: ResponseType.stream,
              receiveTimeout: const Duration(minutes: 5),
              headers: offset > 0 ? {'Range': 'bytes=$offset-'} : null,
            ),
          );
          final append =
              offset > 0 &&
              response.statusCode == 206 &&
              response.headers
                      .value('content-range')
                      ?.startsWith('bytes $offset-') ==
                  true;
          final sink = partial.openWrite(
            mode: append ? FileMode.append : FileMode.write,
          );
          try {
            await sink.addStream(response.data!.stream);
          } finally {
            await sink.close();
          }
          if (cancel.isCancelled) throw StateError("Đã hủy tải");
          if (!await _valid(partial, c)) {
            await partial.delete();
            throw StateError(
              'Audio chưa tải đủ hoặc không khớp. Vui lòng thử lại.',
            );
          }
          await partial.rename(file.path);
        }
        progress(++done, ready.length);
      }
      if (cancel.isCancelled) throw StateError("Đã hủy tải");
      final target = await _manifest(edition);
      final pending = File('${target.path}.new');
      await pending.writeAsString(jsonEncode(manifest), flush: true);
      await pending.rename(target.path);
    } finally {
      _busy.remove(edition);
    }
  }

  Future<bool> _valid(File file, Map c) async =>
      await file.exists() &&
      await file.length() == (c['bytes'] as num).toInt() &&
      (await sha256.bind(file.openRead()).first).toString() == c['sha256'];
  Future<void> delete(String edition) async {
    if (_busy.contains(edition)) throw StateError('Hãy hủy tải trước khi xóa');
    final dir = (await _manifest(edition)).parent;
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
