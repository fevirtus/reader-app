import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/novel_model.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/network/providers.dart';

const chapterPageSize = 50;

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

class ChapterListQuery {
  const ChapterListQuery({required this.novelId, this.page = 1});

  final String novelId;
  final int page;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterListQuery &&
        other.novelId == novelId &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(novelId, page);
}

class ChapterListPage {
  const ChapterListPage({
    required this.chapters,
    required this.totalChapters,
    required this.totalPages,
    required this.currentPage,
  });

  final List<ChapterListItem> chapters;
  final int totalChapters;
  final int totalPages;
  final int currentPage;
}

final chapterListProvider =
    FutureProvider.family<ChapterListPage, ChapterListQuery>((ref, query) async {
  final client = ref.read(apiClientProvider);

  Future<Map<String, dynamic>> fetchChapterPage(String idOrSlug) async {
    final res = await client.dio.get(
      '/api/truyen/$idOrSlug/chapters',
      queryParameters: {
        'page': query.page,
        'limit': chapterPageSize,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  var data = await fetchChapterPage(query.novelId);
  var chapters = data['chapters'] as List? ?? const [];

  // Backend stores chapters by novel id in MongoDB; if route opened by slug,
  // first request can return empty list. Resolve canonical id and retry once.
  if (chapters.isEmpty) {
    try {
      final novelRes = await client.dio.get('/api/novels/${query.novelId}');
      final novelData = novelRes.data as Map<String, dynamic>;
      final canonicalId = novelData['id'] as String?;
      if (canonicalId != null && canonicalId.isNotEmpty && canonicalId != query.novelId) {
        data = await fetchChapterPage(canonicalId);
        chapters = data['chapters'] as List? ?? const [];
      }
    } catch (_) {
      // Keep original empty list when fallback resolution fails.
    }
  }

  return ChapterListPage(
    chapters:
        chapters.map((e) => ChapterListItem.fromJson(e as Map<String, dynamic>)).toList(),
    totalChapters: (data['totalChapters'] as num?)?.toInt() ?? 0,
    totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
    currentPage: (data['currentPage'] as num?)?.toInt() ?? query.page,
  );
});
