import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/novel_model.dart';
import '../storage/database/app_database.dart';
import '../storage/database/mappers.dart';

class GenresRepository {
  GenresRepository(this._db);

  final AppDatabase _db;

  Stream<List<GenreModel>> watchGenres() {
    final query = _db.select(_db.genres)..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch().map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<void> replaceAll(List<GenreModel> genres) async {
    await _db.transaction(() async {
      await _db.delete(_db.genres).go();
      if (genres.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.genres, genres.map((g) => g.toCompanion()).toList());
        });
      }
    });
    await _db.touchSync('genres');
  }
}

final genresRepositoryProvider = Provider<GenresRepository>((ref) {
  return GenresRepository(ref.watch(appDatabaseProvider));
});
