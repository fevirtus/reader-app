import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/models/novel_model.dart';
import '../../../core/network/providers.dart';

class HomeData {
  final List<NovelModel> hot;
  final List<NovelModel> latest;
  final List<NovelModel> topRated;

  const HomeData({
    required this.hot,
    required this.latest,
    required this.topRated,
  });
}

final homeProvider = FutureProvider<HomeData>((ref) async {
  final client = ref.read(apiClientProvider);

  final results = await Future.wait<Response<dynamic>>([
    client.dio.get('/api/novels/browse', queryParameters: {'sort': 'popular', 'limit': '10', 'page': '1'}),
    client.dio.get('/api/novels/browse', queryParameters: {'sort': 'latest', 'limit': '20', 'page': '1'}),
    client.dio.get('/api/novels/browse', queryParameters: {'sort': 'rating', 'limit': '10', 'page': '1'}),
  ]);

  List<NovelModel> parseItems(Response<dynamic> res, String feedName) {
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

  return HomeData(
    hot: parseItems(results[0], 'popular'),
    latest: parseItems(results[1], 'latest'),
    topRated: parseItems(results[2], 'rating'),
  );
});
