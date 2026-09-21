import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/models/novel_model.dart';
import '../../../core/network/providers.dart';
import '../../../core/repositories/novels_repository.dart';

class HomeData {
  final List<NovelModel> hot;
  final List<NovelModel> latest;
  final List<NovelModel> topRated;
  final List<NovelModel> topViews;

  const HomeData({
    required this.hot,
    required this.latest,
    required this.topRated,
    required this.topViews,
  });

  bool get isEmpty => hot.isEmpty && latest.isEmpty && topRated.isEmpty && topViews.isEmpty;
}

// ─── Đọc từ DB cục bộ (offline-first) ─────────────────────────────────────────

final _homeFeedHotProvider = StreamProvider<List<NovelModel>>((ref) {
  return ref.watch(novelsRepositoryProvider).watchHomeFeed('hot');
});

final _homeFeedLatestProvider = StreamProvider<List<NovelModel>>((ref) {
  return ref.watch(novelsRepositoryProvider).watchHomeFeed('latest');
});

final _homeFeedTopRatedProvider = StreamProvider<List<NovelModel>>((ref) {
  return ref.watch(novelsRepositoryProvider).watchHomeFeed('topRated');
});

final _homeFeedTopViewsProvider = StreamProvider<List<NovelModel>>((ref) {
  return ref.watch(novelsRepositoryProvider).watchHomeFeed('topViews');
});

/// Dữ liệu Trang chủ hiện có trong DB cục bộ — luôn có giá trị ngay lập tức
/// (kể cả khi ngoại tuyến), không cần đợi network.
final homeDataProvider = Provider<HomeData>((ref) {
  return HomeData(
    hot: ref.watch(_homeFeedHotProvider).valueOrNull ?? const [],
    latest: ref.watch(_homeFeedLatestProvider).valueOrNull ?? const [],
    topRated: ref.watch(_homeFeedTopRatedProvider).valueOrNull ?? const [],
    topViews: ref.watch(_homeFeedTopViewsProvider).valueOrNull ?? const [],
  );
});

// ─── Đồng bộ nền: gọi API rồi ghi vào DB, DB thay đổi sẽ tự phát lại cho UI ──

class HomeSyncNotifier extends StateNotifier<AsyncValue<void>> {
  HomeSyncNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  bool _hasSyncedOnce = false;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(apiClientProvider);
      final repo = _ref.read(novelsRepositoryProvider);

      final results = await Future.wait<Response<dynamic>>([
        client.dio.get('/api/novels/browse', queryParameters: {'sort': 'popular', 'limit': '10', 'page': '1'}),
        client.dio.get('/api/novels/browse', queryParameters: {'sort': 'latest', 'limit': '20', 'page': '1'}),
        client.dio.get('/api/novels/browse', queryParameters: {'sort': 'rating', 'limit': '10', 'page': '1'}),
      ]);

      final hot = _parseItems(results[0], 'popular');
      final latest = _parseItems(results[1], 'latest');
      final topRated = _parseItems(results[2], 'rating');

      await repo.saveHomeFeed('hot', hot);
      await repo.saveHomeFeed('latest', latest);
      await repo.saveHomeFeed('topRated', topRated);
      await repo.saveHomeFeed('topViews', hot.take(10).toList());

      _hasSyncedOnce = true;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Chỉ đồng bộ tự động một lần khi có mạng — tránh gọi API lặp lại mỗi khi
  /// widget rebuild, trong khi UI đã có sẵn dữ liệu cache để hiển thị ngay.
  Future<void> ensureSyncedIfOnline() async {
    if (_hasSyncedOnce) return;
    final online = await _ref.read(connectivityServiceProvider).checkIsOnline();
    if (online) await refresh();
  }

  List<NovelModel> _parseItems(Response<dynamic> res, String feedName) {
    final raw = res.data;
    if (raw is! Map<String, dynamic>) {
      throw FormatException('Feed $feedName response is not a JSON object: ${raw.runtimeType}');
    }

    final rawItems = raw['items'];
    if (rawItems is! List) {
      throw FormatException('Feed $feedName missing items list');
    }

    final parsed = <NovelModel>[];
    for (var i = 0; i < rawItems.length; i++) {
      final item = rawItems[i];
      if (item is! Map<String, dynamic>) {
        debugPrint('[HOME][SKIP] $feedName item#$i has invalid type: ${item.runtimeType}');
        continue;
      }

      try {
        parsed.add(NovelModel.fromJson(item));
      } catch (e) {
        final id = item['id'];
        debugPrint('[HOME][SKIP] $feedName item#$i id=$id parse failed: $e');
      }
    }

    debugPrint('[HOME] $feedName parsed ${parsed.length}/${rawItems.length} items');
    return parsed;
  }
}

final homeSyncProvider = StateNotifierProvider<HomeSyncNotifier, AsyncValue<void>>((ref) {
  final notifier = HomeSyncNotifier(ref);
  unawaited(notifier.ensureSyncedIfOnline());
  return notifier;
});
