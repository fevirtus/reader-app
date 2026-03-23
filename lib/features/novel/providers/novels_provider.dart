import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/novel_model.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/network/providers.dart';

// ─── Browse / Search ──────────────────────────────────────────────────────────

class BrowseParams {
  final String? query;
  final String? genre;
  final String? status;
  final String sort;
  final int page;

  const BrowseParams({
    this.query,
    this.genre,
    this.status,
    this.sort = 'latest',
    this.page = 1,
  });

  Map<String, dynamic> toQueryParams() => {
        if (query != null && query!.isNotEmpty) 'q': query,
        if (genre != null) 'genre': genre,
        if (status != null) 'status': status,
        'sort': sort,
        'page': page.toString(),
        'limit': '20',
      };

  BrowseParams copyWith({
    String? query,
    String? genre,
    String? status,
    String? sort,
    int? page,
    bool clearQuery = false,
    bool clearGenre = false,
    bool clearStatus = false,
  }) =>
      BrowseParams(
        query: clearQuery ? null : query ?? this.query,
        genre: clearGenre ? null : genre ?? this.genre,
        status: clearStatus ? null : status ?? this.status,
        sort: sort ?? this.sort,
        page: page ?? this.page,
      );
}

class BrowseResult {
  final List<NovelModel> items;
  final int totalCount;
  final int totalPages;
  final int currentPage;

  const BrowseResult({
    required this.items,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
  });
}

class NovelsNotifier extends StateNotifier<AsyncValue<BrowseResult>> {
  final Ref _ref;
  BrowseParams _params = const BrowseParams();

  NovelsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  BrowseParams get params => _params;

  Future<void> fetch({BrowseParams? params}) async {
    if (params != null) _params = params;
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(apiClientProvider);
      final res = await client.dio.get('/api/novels/browse', queryParameters: _params.toQueryParams());
      final data = res.data as Map<String, dynamic>;
      state = AsyncValue.data(BrowseResult(
        items: (data['items'] as List).map((e) => NovelModel.fromJson(e as Map<String, dynamic>)).toList(),
        totalCount: data['totalCount'] as int,
        totalPages: data['totalPages'] as int,
        currentPage: data['currentPage'] as int,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateParams(BrowseParams params) => fetch(params: params);
}

final novelsProvider = StateNotifierProvider<NovelsNotifier, AsyncValue<BrowseResult>>((ref) {
  return NovelsNotifier(ref);
});

// ─── Novel Detail ─────────────────────────────────────────────────────────────

final novelDetailProvider =
    FutureProvider.family<NovelModel, String>((ref, idOrSlug) async {
  final client = ref.read(apiClientProvider);
  final res = await client.dio.get('/api/novels/$idOrSlug');
  return NovelModel.fromJson(res.data as Map<String, dynamic>);
});

// ─── Chapter List ─────────────────────────────────────────────────────────────

final chapterListProvider =
    FutureProvider.family<List<ChapterListItem>, String>((ref, novelId) async {
  final client = ref.read(apiClientProvider);
  final res = await client.dio.get('/api/truyen/$novelId/chapters');
  final data = res.data as Map<String, dynamic>;
  final chapters = data['chapters'] as List? ?? [];
  return chapters
      .map((e) => ChapterListItem.fromJson(e as Map<String, dynamic>))
      .toList();
});
