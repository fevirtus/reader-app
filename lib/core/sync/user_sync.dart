import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../network/providers.dart';
import '../storage/offline_store.dart';
import '../../features/auth/providers/auth_provider.dart';

final syncRevisionProvider = StateProvider<int>((ref) => 0);
final syncErrorProvider = StateProvider<String?>((ref) => null);

class UserSync {
  UserSync(this.ref);
  final Ref ref;
  bool _busy = false;
  bool get isBusy => _busy;
  OfflineStore get store => ref.read(offlineStoreProvider);

  Future<void> enqueue(
    String owner,
    Map<String, dynamic> action, {
    DateTime? occurredAt,
  }) async {
    final id = const Uuid().v4();
    final event = {
      ...action,
      'eventId': id,
      'occurredAt': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
    };
    await store.db.transaction(() async {
      if (action['kind'] == 'progress') {
        for (final entry in (await store.entries(owner, 'outbox:')).entries) {
          final old = entry.value;
          if (old['kind'] == 'progress' &&
              old['novelId'] == action['novelId'] &&
              old['chapterId'] == action['chapterId']) {
            if ((old['occurredAt'] as String).compareTo(
                  event['occurredAt'] as String,
                ) >
                0) {
              return;
            }
            await store.remove(owner, entry.key);
          }
        }
      }
      if (action['kind'] == 'progress') {
        await store.write(owner, 'progress:${action['novelId']}', {
          'chapterId': action['chapterId'],
          'chapterNumber': action['chapterNumber'],
          'scrollOffset': action['progress'] ?? 0.0,
        });
      }
      await store.write(owner, 'outbox:$id', event);
    });
    ref.read(syncRevisionProvider.notifier).state++;
    unawaited(flush());
  }

  Future<void> flush() async {
    if (_busy) return;
    final owner = ref.read(currentUserProvider)?.id;
    if (owner == null) return;
    _busy = true;
    try {
      final token = await ref.read(secureStoreProvider).getAccessToken();
      if (token == null || ref.read(currentUserProvider)?.id != owner) return;
      while (ref.read(currentUserProvider)?.id == owner) {
        final pending = (await store.entries(owner, 'outbox:')).entries.toList()
          ..sort(
            (a, b) => (a.value['occurredAt'] as String).compareTo(
              b.value['occurredAt'] as String,
            ),
          );
        if (pending.isEmpty) break;
        for (final entry in pending) {
          if (ref.read(currentUserProvider)?.id != owner) return;
          final response = await ref
              .read(apiClientProvider)
              .dio
              .post(
                '/api/user/sync',
                data: entry.value,
                options: Options(headers: {'Authorization': 'Bearer $token'}),
              );
          // Do not drop offline edits if an older server ignores the new protocol.
          if (response.data is! Map ||
              response.data['acknowledgedEventId'] != entry.value['eventId']) {
            throw StateError('API chưa hỗ trợ đồng bộ ngoại tuyến');
          }
          await store.db.transaction(() async {
            final list = List<Map<String, dynamic>>.from(
              (await store.read(owner, 'bookshelf') as List? ?? []).map(
                (e) => Map<String, dynamic>.from(e),
              ),
            );
            list.removeWhere((b) => b['novelId'] == entry.value['novelId']);
            final bookmark = response.data['bookmark'];
            if (bookmark != null) list.add(Map<String, dynamic>.from(bookmark));
            await store.write(owner, 'bookshelf', list);
            await store.remove(owner, entry.key);
            final novelId = entry.value['novelId'];
            final remaining = (await store.entries(owner, 'outbox:')).values;
            if (!remaining.any((op) => op['novelId'] == novelId)) {
              final current = await store.read(owner, 'progress:$novelId');
              if (bookmark == null || bookmark['lastChapterId'] == null) {
                await store.remove(owner, 'progress:$novelId');
              } else if (current == null ||
                  current['chapterId'] != bookmark['lastChapterId']) {
                await store.write(owner, 'progress:$novelId', {
                  'chapterId': bookmark['lastChapterId'],
                  'chapterNumber': bookmark['lastChapterNumber'],
                  'scrollOffset': 0.0,
                });
              }
            }
          });
          ref.read(syncRevisionProvider.notifier).state++;
        }
      }
      ref.read(syncErrorProvider.notifier).state = null;
    } catch (_) {
      // Keep the durable operation (also on 4xx); never silently discard user data.
      ref.read(syncErrorProvider.notifier).state =
          'Có thay đổi chưa đồng bộ. App sẽ tự thử lại khi kết nối được API.';
    } finally {
      _busy = false;
    }
  }
}

final userSyncProvider = Provider((ref) => UserSync(ref));
