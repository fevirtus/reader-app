import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  final results = await Future.wait([
    client.dio.get('/api/novels/browse', queryParameters: {'sort': 'popular', 'limit': '10', 'page': '1'}),
    client.dio.get('/api/novels/browse', queryParameters: {'sort': 'latest', 'limit': '20', 'page': '1'}),
    client.dio.get('/api/novels/browse', queryParameters: {'sort': 'rating', 'limit': '10', 'page': '1'}),
  ]);

  List<NovelModel> parseItems(dynamic res) {
    final data = res.data as Map<String, dynamic>;
    return (data['items'] as List)
        .map((e) => NovelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  return HomeData(
    hot: parseItems(results[0]),
    latest: parseItems(results[1]),
    topRated: parseItems(results[2]),
  );
});
