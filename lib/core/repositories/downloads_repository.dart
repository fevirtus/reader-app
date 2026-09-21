import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/novel_model.dart';
import '../storage/database/app_database.dart';
import '../storage/database/mappers.dart';

class DownloadWithNovel {
  const DownloadWithNovel({required this.download, this.novel});
  final Download download;
  final NovelModel? novel;
}

/// queued | downloading | done | failed | paused
class DownloadsRepository {
  DownloadsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Download>> watchAll() {
    final query = _db.select(_db.downloads)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch();
  }

  /// Danh sách truyện đã/đang tải kèm thông tin truyện (bìa, tiêu đề...) cho
  /// màn hình "Đã tải xuống".
  Stream<List<DownloadWithNovel>> watchAllWithNovels() {
    final query = _db.select(_db.downloads).join([
      leftOuterJoin(_db.novels, _db.novels.id.equalsExp(_db.downloads.novelId)),
    ])
      ..orderBy([OrderingTerm.desc(_db.downloads.updatedAt)]);
    return query.watch().map((rows) => rows
        .map((r) => DownloadWithNovel(
              download: r.readTable(_db.downloads),
              novel: r.readTableOrNull(_db.novels)?.toModel(),
            ))
        .toList());
  }

  Stream<Download?> watchForNovel(String novelId) {
    final query = _db.select(_db.downloads)..where((t) => t.novelId.equals(novelId));
    return query.watchSingleOrNull();
  }

  Future<void> upsert({
    required String novelId,
    required String status,
    int? totalChapters,
    int? downloadedChapters,
    int? bytesSize,
    String? errorMessage,
  }) {
    return _db.into(_db.downloads).insertOnConflictUpdate(
          DownloadsCompanion.insert(
            novelId: novelId,
            status: status,
            totalChapters: totalChapters == null ? const Value.absent() : Value(totalChapters),
            downloadedChapters:
                downloadedChapters == null ? const Value.absent() : Value(downloadedChapters),
            bytesSize: bytesSize == null ? const Value.absent() : Value(bytesSize),
            errorMessage: Value(errorMessage),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> delete(String novelId) {
    return (_db.delete(_db.downloads)..where((t) => t.novelId.equals(novelId))).go();
  }

  /// Gọi một lần khi app khởi động. Nếu app bị tắt (kill process, crash...)
  /// giữa lúc đang tải, dòng downloads sẽ kẹt vĩnh viễn ở trạng thái
  /// "downloading" vì [DownloadManager] chỉ theo dõi tiến trình đang chạy
  /// trong bộ nhớ — mất hết khi process mới khởi động lại. Đánh dấu lại
  /// thành "paused" để UI hiển thị đúng thực tế và người dùng có thể bấm
  /// tải lại thay vì thấy vòng xoay tải mãi mãi không tiến triển.
  Future<void> recoverStaleDownloads() async {
    await (_db.update(_db.downloads)..where((t) => t.status.equals('downloading'))).write(
      DownloadsCompanion(status: const Value('paused'), updatedAt: Value(DateTime.now())),
    );
  }
}

final downloadsRepositoryProvider = Provider<DownloadsRepository>((ref) {
  final repo = DownloadsRepository(ref.watch(appDatabaseProvider));
  unawaited(repo.recoverStaleDownloads());
  return repo;
});
