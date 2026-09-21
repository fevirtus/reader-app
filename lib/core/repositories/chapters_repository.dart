import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chapter_model.dart';
import '../storage/database/app_database.dart';
import '../storage/database/mappers.dart';

/// Lưu trữ nội dung chương cục bộ. Phục vụ hai nhu cầu khác nhau trên cùng một bảng:
/// - Cache tạm khi đọc online (fallback khi mất mạng giữa chừng).
/// - Tải hẳn về để đọc ngoại tuyến chủ động (cờ [isDownloaded], không bị dọn dẹp).
class ChaptersRepository {
  ChaptersRepository(this._db);

  final AppDatabase _db;

  /// Cache "thụ động" khi người dùng mở một chương qua mạng — không được hạ cờ
  /// isDownloaded nếu chương này trước đó đã được tải chủ động.
  Future<void> cacheViewedChapter(ChapterModel chapter) async {
    final existing = await (_db.select(_db.chapterContents)
          ..where((t) => t.chapterId.equals(chapter.id)))
        .getSingleOrNull();
    await _db.into(_db.chapterContents).insertOnConflictUpdate(
          chapter.toCompanion(isDownloaded: existing?.isDownloaded ?? false),
        );
  }

  Future<void> saveDownloadedChapter(ChapterModel chapter) async {
    await _db.into(_db.chapterContents).insertOnConflictUpdate(
          chapter.toCompanion(isDownloaded: true),
        );
  }

  Future<ChapterModel?> getCachedChapter(String chapterId) async {
    final row = await (_db.select(_db.chapterContents)
          ..where((t) => t.chapterId.equals(chapterId)))
        .getSingleOrNull();
    return row?.toModel();
  }

  Stream<Set<String>> watchDownloadedChapterIds(String novelId) {
    final query = _db.select(_db.chapterContents)
      ..where((t) => t.novelId.equals(novelId) & t.isDownloaded.equals(true));
    return query.watch().map((rows) => rows.map((r) => r.chapterId).toSet());
  }

  Future<void> deleteNovelChapters(String novelId) async {
    await (_db.delete(_db.chapterContents)..where((t) => t.novelId.equals(novelId))).go();
  }

  Future<int> getDownloadedSizeBytes(String novelId) async {
    final result = await _db.customSelect(
      'SELECT SUM(LENGTH(content)) AS total FROM chapter_contents '
      'WHERE novel_id = ? AND is_downloaded = 1',
      variables: [Variable.withString(novelId)],
      readsFrom: {_db.chapterContents},
    ).getSingleOrNull();
    return (result?.data['total'] as int?) ?? 0;
  }
}

final chaptersRepositoryProvider = Provider<ChaptersRepository>((ref) {
  return ChaptersRepository(ref.watch(appDatabaseProvider));
});
