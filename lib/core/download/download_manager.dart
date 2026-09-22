import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chapter_model.dart';
import '../models/novel_model.dart';
import '../network/providers.dart';
import '../repositories/chapters_repository.dart';
import '../repositories/downloads_repository.dart';
import '../repositories/novels_repository.dart';
import '../storage/offline_store.dart';
import '../../features/novel/providers/novels_provider.dart';
import '../../features/reader/providers/reader_provider.dart';

class DownloadManager {
  DownloadManager(this._ref);
  final Ref _ref;
  final Set<String> _cancelled = {};
  final Map<String, Future<void>> _active = {};
  bool isDownloading(String id) => _active.containsKey(id);

  Future<Map<String, dynamic>> _manifest(String id) async {
    final r = await _ref
        .read(apiClientProvider)
        .dio
        .get('/api/novels/$id/download-manifest');
    return Map<String, dynamic>.from(r.data);
  }

  Future<void> startDownload(String id) {
    if (_active.containsKey(id)) return _active[id]!;
    _cancelled.remove(id);
    final task = _download(id);
    _active[id] = task;
    return task.whenComplete(() {
      _active.remove(id);
      _cancelled.remove(id);
    });
  }

  Future<void> _download(String id) async {
    final downloads = _ref.read(downloadsRepositoryProvider);
    final chapters = _ref.read(chaptersRepositoryProvider);
    final store = _ref.read(offlineStoreProvider);
    final owner = 'download:$id';
    int done = 0;
    int total = 0;
    try {
      final manifest = await _manifest(id);
      final meta = List<Map<String, dynamic>>.from(
        (manifest['chapters'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
      total = meta.length;
      if (total == 0) throw StateError('Truyện chưa có chương để tải');
      if (_cancelled.contains(id)) return;
      final novelResponse = await _ref
          .read(apiClientProvider)
          .dio
          .get('/api/novels/$id');
      await _ref
          .read(novelsRepositoryProvider)
          .saveNovelDetail(NovelModel.fromJson(novelResponse.data));
      await downloads.upsert(
        novelId: id,
        status: 'downloading',
        totalChapters: total,
        downloadedChapters: 0,
      );
      for (final entry in meta) {
        if (_cancelled.contains(id)) {
          await downloads.upsert(
            novelId: id,
            status: 'paused',
            totalChapters: total,
            downloadedChapters: done,
          );
          return;
        }
        final chapterId = entry['id'] as String;
        final hash = entry['contentHash'] as String?;
        if (hash == null || hash.isEmpty) {
          throw StateError(
            'Chương chưa có phiên bản nội dung, hãy thử lại sau',
          );
        }
        var saved = await store.read(owner, chapterId);
        // Reuse intact staged or downloaded content; fetch only missing/changed chapters.
        if (saved == null || saved['contentHash'] != hash) {
          final local = await chapters.getDownloadedChapter(chapterId);
          if (local != null &&
              sha256.convert(utf8.encode(local.content)).toString() == hash) {
            saved = {...local.toJson(), 'contentHash': hash};
          } else {
            final r = await _ref
                .read(apiClientProvider)
                .dio
                .get('/api/chapters/$chapterId');
            final c = ChapterModel.fromJson(Map<String, dynamic>.from(r.data));
            if (c.novelId != id ||
                sha256.convert(utf8.encode(c.content)).toString() != hash) {
              throw StateError(
                'Nội dung vừa thay đổi trên server. Bản cũ được giữ nguyên; hãy thử cập nhật lại',
              );
            }
            saved = {...c.toJson(), 'contentHash': hash};
          }
        }
        if (_cancelled.contains(id)) {
          await downloads.upsert(novelId: id, status: 'paused');
          return;
        }
        saved = Map<String, dynamic>.from(saved)
          ..['title'] = entry['title']
          ..['number'] = entry['number'];
        await store.write(owner, chapterId, saved);
        done++;
        await downloads.upsert(
          novelId: id,
          status: 'downloading',
          totalChapters: total,
          downloadedChapters: done,
        );
      }
      final latest = await _manifest(id);
      if (latest['revision'] != manifest['revision']) {
        throw StateError(
          'Danh sách/nội dung chương đã đổi trong lúc tải. Bản cũ vẫn được giữ; hãy thử lại',
        );
      }
      if (_cancelled.contains(id)) {
        await downloads.upsert(novelId: id, status: 'paused');
        return;
      }
      await store.db.transaction(() async {
        // Commit contents, navigation and status together; no half-updated download.
        await chapters.replaceDownloadFrom(
          id,
          meta,
          (chapterId) async => ChapterModel.fromJson(
            Map<String, dynamic>.from(await store.read(owner, chapterId)),
          ),
        );
        await downloads.upsert(
          novelId: id,
          status: 'done',
          totalChapters: total,
          downloadedChapters: total,
          bytesSize: await chapters.getDownloadedSizeBytes(id),
        );
        for (final key in (await store.entries(owner, '')).keys) {
          await store.remove(owner, key);
        }
      });
      if (_ref.exists(novelDetailProvider(id))) {
        _ref.invalidate(novelDetailProvider(id));
      }
      if (_ref.exists(chapterListProvider(id))) {
        _ref.invalidate(chapterListProvider(id));
      }
      for (final entry in meta) {
        final provider = chapterProvider(entry['id'] as String);
        if (_ref.exists(provider)) _ref.invalidate(provider);
      }
    } catch (e) {
      await downloads.upsert(
        novelId: id,
        status: _cancelled.contains(id) ? 'paused' : 'failed',
        totalChapters: total == 0 ? null : total,
        downloadedChapters: done,
        errorMessage: 'Không cập nhật được. Bản tải cũ vẫn còn. $e',
      );
    }
  }

  void cancelDownload(String id) => _cancelled.add(id);

  Future<void> deleteDownload(String id) async {
    cancelDownload(id);
    // Wait for in-flight requests/transaction before deleting; nothing can resurrect it.
    await _active[id];
    final store = _ref.read(offlineStoreProvider);
    await store.db.transaction(() async {
      await _ref.read(chaptersRepositoryProvider).deleteNovelChapters(id);
      await _ref.read(downloadsRepositoryProvider).delete(id);
      for (final key in (await store.entries('download:$id', '')).keys) {
        await store.remove('download:$id', key);
      }
    });
    if (_ref.exists(chapterListProvider(id))) {
      _ref.invalidate(chapterListProvider(id));
    }
  }
}

final downloadManagerProvider = Provider((ref) => DownloadManager(ref));
