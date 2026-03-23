import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/comment_model.dart';
import '../../../core/network/providers.dart';

class CommentsNotifier extends StateNotifier<AsyncValue<List<CommentModel>>> {
  final Ref _ref;
  final String novelId;
  final String? chapterId;
  int _page = 1;
  bool _hasMore = true;

  CommentsNotifier(this._ref, {required this.novelId, this.chapterId})
      : super(const AsyncValue.loading()) {
    fetch();
  }

  bool get hasMore => _hasMore;

  Future<void> fetch({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }
    try {
      final client = _ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{
        'page': _page.toString(),
        'limit': '20',
        if (chapterId != null) 'chapterId': chapterId,
      };
      final res = await client.dio.get('/api/truyen/$novelId/comments', queryParameters: queryParams);
      final data = res.data as Map<String, dynamic>;
      final newItems = (data['comments'] as List)
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final totalPages = data['totalPages'] as int? ?? 1;
      _hasMore = _page < totalPages;
      final existing = reset ? <CommentModel>[] : (state.valueOrNull ?? []);
      state = AsyncValue.data([...existing, ...newItems]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    _page++;
    await fetch();
  }

  Future<void> post(String content) async {
    final client = _ref.read(apiClientProvider);
    final res = await client.dio.post('/api/truyen/$novelId/comments', data: {
      'content': content,
      if (chapterId != null) 'chapterId': chapterId,
    });
    final newComment = CommentModel.fromJson(res.data as Map<String, dynamic>);
    state = AsyncValue.data([newComment, ...(state.valueOrNull ?? [])]);
  }
}

// Provider family params: "novelId" or "novelId:chapterId"
final commentsProvider = StateNotifierProvider.family<CommentsNotifier,
    AsyncValue<List<CommentModel>>, String>((ref, key) {
  final parts = key.split(':');
  return CommentsNotifier(
    ref,
    novelId: parts[0],
    chapterId: parts.length > 1 ? parts[1] : null,
  );
});
