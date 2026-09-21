import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chapter_model.dart';
import '../network/providers.dart';
import '../repositories/chapters_repository.dart';
import '../repositories/downloads_repository.dart';

/// Tải toàn bộ chương của một truyện về máy để đọc ngoại tuyến, tuần tự từng
/// chương một (tránh dội API), ghi tiến độ vào bảng `downloads` sau mỗi chương —
/// UI theo dõi tiến độ qua [DownloadsRepository.watchForNovel] (phản ứng qua DB),
/// không cần cơ chế thông báo riêng.
class DownloadManager {
  DownloadManager(this._ref);

  final Ref _ref;
  final Set<String> _cancelledNovelIds = {};
  final Set<String> _activeNovelIds = {};

  bool isDownloading(String novelId) => _activeNovelIds.contains(novelId);

  Future<List<ChapterListItem>> _fetchAllChapterMeta(String novelId) async {
    final client = _ref.read(apiClientProvider);
    const limit = 500;
    var page = 1;
    var totalPages = 1;
    final items = <ChapterListItem>[];

    while (page <= totalPages) {
      final res = await client.dio.get(
        '/api/truyen/$novelId/chapters',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = res.data as Map<String, dynamic>;
      final chapters = data['chapters'] as List? ?? const [];
      items.addAll(chapters.map((e) => ChapterListItem.fromJson(e as Map<String, dynamic>)));

      final apiTotalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      totalPages = apiTotalPages > 0 ? apiTotalPages : 1;
      page += 1;
    }

    return items;
  }

  Future<void> startDownload(String novelId) async {
    if (_activeNovelIds.contains(novelId)) return;
    _activeNovelIds.add(novelId);
    _cancelledNovelIds.remove(novelId);

    final downloadsRepo = _ref.read(downloadsRepositoryProvider);
    final chaptersRepo = _ref.read(chaptersRepositoryProvider);

    try {
      List<ChapterListItem> chapters;
      try {
        chapters = await _fetchAllChapterMeta(novelId);
      } catch (e) {
        await downloadsRepo.upsert(
          novelId: novelId,
          status: 'failed',
          errorMessage: 'Không tải được danh sách chương: $e',
        );
        return;
      }

      if (chapters.isEmpty) {
        await downloadsRepo.upsert(
          novelId: novelId,
          status: 'failed',
          errorMessage: 'Truyện chưa có chương nào',
        );
        return;
      }

      await downloadsRepo.upsert(
        novelId: novelId,
        status: 'downloading',
        totalChapters: chapters.length,
        downloadedChapters: 0,
        errorMessage: null,
      );

      final client = _ref.read(apiClientProvider);
      var done = 0;
      for (final meta in chapters) {
        if (_cancelledNovelIds.contains(novelId)) {
          await downloadsRepo.upsert(
            novelId: novelId,
            status: 'paused',
            totalChapters: chapters.length,
            downloadedChapters: done,
          );
          return;
        }

        try {
          final res = await client.dio.get('/api/chapters/${meta.id}');
          final chapter = ChapterModel.fromJson(res.data as Map<String, dynamic>);
          await chaptersRepo.saveDownloadedChapter(chapter);
          done += 1;
          await downloadsRepo.upsert(
            novelId: novelId,
            status: 'downloading',
            totalChapters: chapters.length,
            downloadedChapters: done,
          );
        } catch (e) {
          debugPrint('[DOWNLOAD][ERROR] novel=$novelId chapter=${meta.id} $e');
          await downloadsRepo.upsert(
            novelId: novelId,
            status: 'failed',
            totalChapters: chapters.length,
            downloadedChapters: done,
            errorMessage: 'Lỗi tải chương ${meta.number}: $e',
          );
          return;
        }
      }

      final bytes = await chaptersRepo.getDownloadedSizeBytes(novelId);
      await downloadsRepo.upsert(
        novelId: novelId,
        status: 'done',
        totalChapters: chapters.length,
        downloadedChapters: done,
        bytesSize: bytes,
      );
    } finally {
      _activeNovelIds.remove(novelId);
      _cancelledNovelIds.remove(novelId);
    }
  }

  void cancelDownload(String novelId) {
    _cancelledNovelIds.add(novelId);
  }

  Future<void> deleteDownload(String novelId) async {
    cancelDownload(novelId);
    await _ref.read(chaptersRepositoryProvider).deleteNovelChapters(novelId);
    await _ref.read(downloadsRepositoryProvider).delete(novelId);
  }
}

final downloadManagerProvider = Provider<DownloadManager>((ref) => DownloadManager(ref));
