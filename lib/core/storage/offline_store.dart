import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart';

/// Transactional, account-scoped snapshots and durable outgoing operations.
class OfflineStore {
  OfflineStore(this.db);
  final AppDatabase db;

  Future<dynamic> read(String owner, String key) async {
    final rows = await db
        .customSelect(
          'SELECT value FROM offline_store WHERE owner = ? AND key = ?',
          variables: [Variable(owner), Variable(key)],
        )
        .get();
    return rows.isEmpty ? null : jsonDecode(rows.single.read<String>('value'));
  }

  Future<void> write(String owner, String key, Object value) =>
      db.customStatement(
        'INSERT INTO offline_store(owner, key, value) VALUES (?, ?, ?) '
        'ON CONFLICT(owner, key) DO UPDATE SET value = excluded.value',
        [owner, key, jsonEncode(value)],
      );

  Future<void> remove(String owner, String key) => db.customStatement(
    'DELETE FROM offline_store WHERE owner = ? AND key = ?',
    [owner, key],
  );

  Future<Map<String, dynamic>> entries(String owner, String prefix) async {
    final rows = await db
        .customSelect(
          'SELECT key, value FROM offline_store WHERE owner = ? AND substr(key, 1, ?) = ? ORDER BY key',
          variables: [
            Variable(owner),
            Variable(prefix.length),
            Variable(prefix),
          ],
        )
        .get();
    return {
      for (final r in rows)
        r.read<String>('key'): jsonDecode(r.read<String>('value')),
    };
  }
}

final offlineStoreProvider = Provider(
  (ref) => OfflineStore(ref.watch(appDatabaseProvider)),
);
