import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/novel_model.dart';
import '../../../core/network/providers.dart';

final genresProvider = FutureProvider<List<GenreModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  final res = await client.dio.get('/api/genres');
  return (res.data as List)
      .map((e) => GenreModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
