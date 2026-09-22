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
    final existing = await (_db.select(
      _db.chapterContents,
    )..where((t) => t.chapterId.equals(chapter.id))).getSingleOrNull();
    if (existing?.isDownloaded == true) return;
    // Conditional UPSERT closes the race with an atomic download commit.
    await _db
        .into(_db.chapterContents)
        .insert(
          chapter.toCompanion(isDownloaded: false),
          onConflict: DoUpdate(
            (old) => chapter.toCompanion(isDownloaded: false),
            where: (old) => old.isDownloaded.equals(false),
          ),
        );
  }

  Future<void> saveDownloadedChapter(ChapterModel chapter) async {
    await _db
        .into(_db.chapterContents)
        .insertOnConflictUpdate(chapter.toCompanion(isDownloaded: true));
  }

  Future<ChapterModel?> getCachedChapter(String chapterId) async {
    final row = await (_db.select(
      _db.chapterContents,
    )..where((t) => t.chapterId.equals(chapterId))).getSingleOrNull();
    return row?.toModel();
  }

  Future<ChapterModel?> getDownloadedChapter(String chapterId) async {
    final row =
        await (_db.select(_db.chapterContents)..where(
              (t) =>
                  t.chapterId.equals(chapterId) & t.isDownloaded.equals(true),
            ))
            .getSingleOrNull();
    return row?.toModel();
  }

  Future<bool> hasDownload(String novelId) async {
    final table = _db.chapterContents;
    final query = _db.selectOnly(table)
      ..addColumns([table.chapterId])
      ..where(table.novelId.equals(novelId) & table.isDownloaded.equals(true))
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  Future<List<ChapterListItem>> cachedContentsList(String novelId) async {
    final table = _db.chapterContents;
    // Never materialize chapter bodies just to render a table of contents.
    final query = _db.selectOnly(table)
      ..addColumns([
        table.chapterId,
        table.number,
        table.title,
        table.volumeTitle,
        table.cachedAt,
      ])
      ..where(table.novelId.equals(novelId) & table.isDownloaded.equals(true))
      ..orderBy([OrderingTerm.asc(table.number)]);
    return (await query.get())
        .map(
          (row) => ChapterListItem(
            id: row.read(table.chapterId)!,
            number: row.read(table.number)!,
            title: row.read(table.title)!,
            volumeTitle: row.read(table.volumeTitle),
            createdAt: row.read(table.cachedAt)!,
          ),
        )
        .toList();
  }

  Future<List<ChapterListItem>> cachedMeta(String novelId) async {
    final pinned = await cachedContentsList(novelId);
    if (pinned.isNotEmpty) return pinned;
    final rows =
        await (_db.select(_db.chaptersMeta)
              ..where((t) => t.novelId.equals(novelId))
              ..orderBy([(t) => OrderingTerm.asc(t.number)]))
            .get();
    return rows
        .map(
          (r) => ChapterListItem(
            id: r.id,
            number: r.number,
            title: r.title,
            volumeNumber: r.volumeNumber,
            volumeTitle: r.volumeTitle,
            volumeChapterNumber: r.volumeChapterNumber,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }

  Future<void> saveMeta(String novelId, List<ChapterListItem> chapters) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.chaptersMeta,
      )..where((t) => t.novelId.equals(novelId))).go();
      for (final c in chapters) {
        await _db
            .into(_db.chaptersMeta)
            .insertOnConflictUpdate(
              ChaptersMetaCompanion.insert(
                id: c.id,
                novelId: novelId,
                number: c.number,
                title: c.title,
                createdAt: c.createdAt,
                volumeNumber: Value(c.volumeNumber),
                volumeTitle: Value(c.volumeTitle),
                volumeChapterNumber: Value(c.volumeChapterNumber),
              ),
            );
      }
    });
  }

  /// The old complete snapshot remains readable until every new chapter is ready.
  Future<void> replaceDownloadFrom(
    String novelId,
    List<Map<String, dynamic>> chapters,
    Future<ChapterModel> Function(String) load,
  ) async {
    await _db.transaction(() async {
      await deleteNovelChapters(novelId);
      for (var i = 0; i < chapters.length; i++) {
        final c = await load(chapters[i]['id'] as String);
        final json = c.toJson()
          ..['prevChapterId'] = i > 0 ? chapters[i - 1]['id'] : null
          ..['prevChapterNumber'] = i > 0 ? chapters[i - 1]['number'] : null
          ..['nextChapterId'] = i + 1 < chapters.length
              ? chapters[i + 1]['id']
              : null
          ..['nextChapterNumber'] = i + 1 < chapters.length
              ? chapters[i + 1]['number']
              : null;
        await saveDownloadedChapter(ChapterModel.fromJson(json));
      }
    });
  }

  Stream<Set<String>> watchDownloadedChapterIds(String novelId) {
    final table = _db.chapterContents;
    final query = _db.selectOnly(table)
      ..addColumns([table.chapterId])
      ..where(table.novelId.equals(novelId) & table.isDownloaded.equals(true));
    return query.watch().map(
      (rows) => rows.map((r) => r.read(table.chapterId)!).toSet(),
    );
  }

  Future<void> deleteNovelChapters(String novelId) async {
    await (_db.delete(
      _db.chapterContents,
    )..where((t) => t.novelId.equals(novelId))).go();
  }

  Future<int> getDownloadedSizeBytes(String novelId) async {
    final result = await _db
        .customSelect(
          'SELECT SUM(LENGTH(CAST(content AS BLOB))) AS total FROM chapter_contents '
          'WHERE novel_id = ? AND is_downloaded = 1',
          variables: [Variable.withString(novelId)],
          readsFrom: {_db.chapterContents},
        )
        .getSingleOrNull();
    return (result?.data['total'] as int?) ?? 0;
  }
}

final chaptersRepositoryProvider = Provider<ChaptersRepository>((ref) {
  return ChaptersRepository(ref.watch(appDatabaseProvider));
});
