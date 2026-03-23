import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chapter_model.dart';

class OfflineCache {
  static const _dbName = 'reader_offline.db';
  static const _version = 1;

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE cached_chapters (
            id TEXT PRIMARY KEY,
            novel_id TEXT NOT NULL,
            chapter_number INTEGER NOT NULL,
            title TEXT,
            content TEXT NOT NULL,
            prev_chapter_id TEXT,
            prev_chapter_number INTEGER,
            next_chapter_id TEXT,
            next_chapter_number INTEGER,
            volume_title TEXT,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_novel_chapters ON cached_chapters(novel_id, chapter_number)
        ''');
      },
    );
  }

  Future<void> saveChapter(ChapterModel chapter) async {
    final database = await db;
    await database.insert(
      'cached_chapters',
      {
        'id': chapter.id,
        'novel_id': chapter.novelId,
        'chapter_number': chapter.number,
        'title': chapter.title,
        'content': chapter.content,
        'prev_chapter_id': chapter.prevChapterId,
        'prev_chapter_number': chapter.prevChapterNumber,
        'next_chapter_id': chapter.nextChapterId,
        'next_chapter_number': chapter.nextChapterNumber,
        'volume_title': chapter.volumeTitle,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ChapterModel?> loadChapter(String chapterId) async {
    final database = await db;
    final rows = await database.query(
      'cached_chapters',
      where: 'id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _rowToChapter(rows.first);
  }

  Future<List<String>> cachedChapterIdsForNovel(String novelId) async {
    final database = await db;
    final rows = await database.query(
      'cached_chapters',
      columns: ['id'],
      where: 'novel_id = ?',
      whereArgs: [novelId],
      orderBy: 'chapter_number ASC',
    );
    return rows.map((r) => r['id'] as String).toList();
  }

  Future<void> deleteNovelCache(String novelId) async {
    final database = await db;
    await database.delete(
      'cached_chapters',
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );
  }

  Future<int> getCacheSizeBytes() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT SUM(LENGTH(content)) as total FROM cached_chapters',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  ChapterModel _rowToChapter(Map<String, dynamic> row) {
    return ChapterModel(
      id: row['id'] as String,
      novelId: row['novel_id'] as String,
      number: row['chapter_number'] as int,
      title: (row['title'] as String?) ?? '',
      content: row['content'] as String,
      prevChapterId: row['prev_chapter_id'] as String?,
      prevChapterNumber: row['prev_chapter_number'] as int?,
      nextChapterId: row['next_chapter_id'] as String?,
      nextChapterNumber: row['next_chapter_number'] as int?,
      volumeTitle: row['volume_title'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['cached_at'] as int),
    );
  }
}

final offlineCacheProvider = Provider<OfflineCache>((_) => OfflineCache());
