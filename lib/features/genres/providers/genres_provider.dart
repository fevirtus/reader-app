import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/models/novel_model.dart';
import '../../../core/network/providers.dart';
import '../../../core/repositories/genres_repository.dart';

/// Danh sách thể loại đọc trực tiếp từ DB cục bộ — có ngay lập tức kể cả ngoại tuyến.
final genresListProvider = StreamProvider<List<GenreModel>>((ref) {
  return ref.watch(genresRepositoryProvider).watchGenres();
});

class GenresSyncNotifier extends StateNotifier<AsyncValue<void>> {
  GenresSyncNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  bool _hasSyncedOnce = false;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(apiClientProvider);
      final res = await client.dio.get('/api/genres');
      final genres = (res.data as List)
          .map((e) => GenreModel.fromJson(e as Map<String, dynamic>))
          .toList();
      await _ref.read(genresRepositoryProvider).replaceAll(genres);
      _hasSyncedOnce = true;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> ensureSyncedIfOnline() async {
    if (_hasSyncedOnce) return;
    final online = await _ref.read(connectivityServiceProvider).checkIsOnline();
    if (online) await refresh();
  }
}

final genresSyncProvider = StateNotifierProvider<GenresSyncNotifier, AsyncValue<void>>((ref) {
  final notifier = GenresSyncNotifier(ref);
  unawaited(notifier.ensureSyncedIfOnline());
  return notifier;
});
