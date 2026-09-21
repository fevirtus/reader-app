import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

/// Truyện đã từng xem/lưu — nguồn dữ liệu cục bộ cho Home, Search, Bookshelf...
class Novels extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get slug => text()();
  TextColumn get authorName => text()();
  TextColumn get status => text()();
  IntColumn get totalChapters => integer().withDefault(const Constant(0))();
  TextColumn get originalTitle => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get coverColor => text().nullable()();
  IntColumn get views => integer().withDefault(const Constant(0))();
  RealColumn get rating => real().withDefault(const Constant(0))();
  IntColumn get ratingCount => integer().withDefault(const Constant(0))();
  RealColumn get userRating => real().nullable()();
  IntColumn get bookmarkCount => integer().withDefault(const Constant(0))();
  TextColumn get seriesId => text().nullable()();
  TextColumn get genresJson => text().nullable()();
  TextColumn get seriesJson => text().nullable()();
  TextColumn get latestChapterJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Genres extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get slug => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get novelCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Bảng nối nhiều-nhiều giữa Novels và Genres.
class NovelGenres extends Table {
  TextColumn get novelId => text()();
  TextColumn get genreId => text()();

  @override
  Set<Column> get primaryKey => {novelId, genreId};
}

/// Metadata danh sách chương — nhẹ, đồng bộ sớm để hiển thị mục lục offline.
class ChaptersMeta extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text()();
  IntColumn get number => integer()();
  TextColumn get title => text()();
  IntColumn get volumeNumber => integer().nullable()();
  TextColumn get volumeTitle => text().nullable()();
  IntColumn get volumeChapterNumber => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Nội dung đầy đủ của chương — chỉ tồn tại khi đã đọc (cache) hoặc đã tải xuống chủ động.
class ChapterContents extends Table {
  TextColumn get chapterId => text()();
  TextColumn get novelId => text()();
  IntColumn get number => integer()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get prevChapterId => text().nullable()();
  IntColumn get prevChapterNumber => integer().nullable()();
  TextColumn get nextChapterId => text().nullable()();
  IntColumn get nextChapterNumber => integer().nullable()();
  TextColumn get volumeTitle => text().nullable()();
  // true = người dùng chủ động tải để đọc ngoại tuyến, không bị dọn dẹp tự động.
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {chapterId};
}

class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get novelId => text()();
  TextColumn get type => text()();
  TextColumn get shelfStatus => text()();
  TextColumn get lastChapterId => text().nullable()();
  IntColumn get lastChapterNumber => integer().nullable()();
  // Danh sách số chương đã đọc, lưu dạng JSON (vd: "[1,2,3]").
  TextColumn get readChaptersJson => text().withDefault(const Constant('[]'))();
  BoolColumn get markedAsRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // true khi thay đổi này chưa được đồng bộ lên server (tạo lúc mất mạng).
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ghi lại danh sách + thứ tự truyện cho từng mục ở Trang chủ (hot, latest, topRated, topViews)
/// để có thể dựng lại y nguyên khi ngoại tuyến. Bản thân dữ liệu truyện nằm ở bảng [Novels].
class HomeFeedItems extends Table {
  TextColumn get section => text()();
  IntColumn get position => integer()();
  TextColumn get novelId => text()();

  @override
  Set<Column> get primaryKey => {section, position};
}

/// Trạng thái tải truyện để đọc ngoại tuyến, một dòng cho mỗi truyện.
class Downloads extends Table {
  TextColumn get novelId => text()();
  // queued | downloading | done | failed | paused
  TextColumn get status => text()();
  IntColumn get totalChapters => integer().withDefault(const Constant(0))();
  IntColumn get downloadedChapters => integer().withDefault(const Constant(0))();
  IntColumn get bytesSize => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {novelId};
}

/// Dấu thời gian đồng bộ lần cuối theo từng "vùng" dữ liệu (vd: "home", "genres", "novel:xyz").
/// Dùng để hiển thị "Cập nhật lần cuối lúc X" khi ngoại tuyến.
class SyncMeta extends Table {
  TextColumn get key => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Novels,
    Genres,
    NovelGenres,
    ChaptersMeta,
    ChapterContents,
    Bookmarks,
    Downloads,
    SyncMeta,
    HomeFeedItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  /// Ghi lại thời điểm đồng bộ thành công cho một vùng dữ liệu.
  Future<void> touchSync(String key) {
    return into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(key: key, lastSyncedAt: DateTime.now()),
    );
  }

  Future<DateTime?> lastSyncedAt(String key) async {
    final row = await (select(syncMeta)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'reader_app.db'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    return NativeDatabase.createInBackground(file, setup: (rawDb) {
      rawDb.execute('PRAGMA foreign_keys = ON;');
    });
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
