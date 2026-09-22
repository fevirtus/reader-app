import '../../../core/repositories/chapters_repository.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/models/novel_model.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/network/providers.dart';
import '../../../core/repositories/novels_repository.dart';

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

  String? _normalizedStatus() {
    final raw = status?.trim();
    if (raw == null || raw.isEmpty) return null;
    switch (raw.toLowerCase()) {
      case 'ongoing':
        return 'ONGOING';
      case 'completed':
        return 'COMPLETED';
      case 'hiatus':
        return 'HIATUS';
      default:
        return raw;
    }
  }

  String _normalizedSort() {
    final raw = sort.trim();
    if (raw.isEmpty) return 'latest';
    switch (raw.toLowerCase()) {
      case 'latest':
      case 'popular':
      case 'rating':
      case 'name':
        return raw.toLowerCase();
      default:
        return 'latest';
    }
  }

  Map<String, dynamic> toQueryParams() => {
    if (query != null && query!.isNotEmpty) 'q': query,
    if (genre != null) 'genre': genre,
    if (_normalizedStatus() != null) 'status': _normalizedStatus(),
    'sort': _normalizedSort(),
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
  }) => BrowseParams(
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
  final bool isLoadingMore;

  const BrowseResult({
    required this.items,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < totalPages;

  BrowseResult copyWith({
    List<NovelModel>? items,
    int? totalCount,
    int? totalPages,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return BrowseResult(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NovelsNotifier extends StateNotifier<AsyncValue<BrowseResult>> {
  final Ref _ref;
  BrowseParams _params = const BrowseParams();
  bool _isLoadingMore = false;

  NovelsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  BrowseParams get params => _params;

  Future<BrowseResult> _fetchPage(BrowseParams params) async {
    final client = _ref.read(apiClientProvider);
    final res = await client.dio.get(
      '/api/novels/browse',
      queryParameters: params.toQueryParams(),
    );
    final data = res.data as Map<String, dynamic>;
    return BrowseResult(
      items: (data['items'] as List)
          .map((e) => NovelModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (data['currentPage'] as num?)?.toInt() ?? params.page,
    );
  }

  Future<void> fetch({BrowseParams? params}) async {
    if (params != null) _params = params;
    state = const AsyncValue.loading();
    try {
      final firstPageParams = _params.copyWith(page: 1);
      final result = await _fetchPage(firstPageParams);
      _params = firstPageParams;
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateParams(BrowseParams params) => fetch(params: params);

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final nextParams = _params.copyWith(page: current.currentPage + 1);
      final nextPage = await _fetchPage(nextParams);
      _params = nextParams;

      final merged = [...current.items, ...nextPage.items];
      state = AsyncValue.data(
        nextPage.copyWith(items: merged, isLoadingMore: false),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }
}

final novelsProvider =
    StateNotifierProvider<NovelsNotifier, AsyncValue<BrowseResult>>((ref) {
      return NovelsNotifier(ref);
    });

// ─── Novel Detail ─────────────────────────────────────────────────────────────

final novelDetailProvider = StreamProvider.family<NovelModel, String>((
  ref,
  idOrSlug,
) async* {
  final repo = ref.read(novelsRepositoryProvider);
  final chapters = ref.read(chaptersRepositoryProvider);
  final client = ref.read(apiClientProvider);
  final connectivity = ref.read(connectivityServiceProvider);
  final cached = await repo.getCachedNovel(idOrSlug);
  if (cached != null) {
    yield cached;
    // A downloaded book opens without a connectivity check or metadata request.
    if (await chapters.hasDownload(cached.id)) return;
  }
  try {
    if (!await connectivity.checkIsOnline()) {
      if (cached != null) return;
      throw Exception('Không có mạng và chưa có dữ liệu đã lưu cho truyện này');
    }
    final res = await client.dio.get('/api/novels/$idOrSlug');
    final novel = NovelModel.fromJson(res.data as Map<String, dynamic>);
    await repo.saveNovelDetail(novel);
    final stored = await repo.getCachedNovel(novel.id);
    yield stored?.updatedAt != null &&
            novel.updatedAt != null &&
            stored!.updatedAt!.isAfter(novel.updatedAt!)
        ? stored
        : novel;
  } catch (_) {
    if (cached == null) rethrow;
    // Background refresh failure must not replace usable local data with an error.
  }
});

// ─── Chapter List ─────────────────────────────────────────────────────────────

final chapterListProvider = StreamProvider.family<List<ChapterListItem>, String>((
  ref,
  novelId,
) async* {
  final chaptersRepo = ref.read(chaptersRepositoryProvider);
  final novelsRepo = ref.read(novelsRepositoryProvider);
  final client = ref.read(apiClientProvider);
  final connectivity = ref.read(connectivityServiceProvider);
  final localNovel = await novelsRepo.getCachedNovel(novelId);
  final canonicalId = localNovel?.id ?? novelId;
  final pinned = await chaptersRepo.cachedContentsList(canonicalId);
  if (pinned.isNotEmpty) {
    yield pinned;
    return;
  }
  final cached = await chaptersRepo.cachedMeta(canonicalId);
  if (cached.isNotEmpty) yield cached;

  Future<List<ChapterListItem>> fetchAllChapters(String idOrSlug) async {
    const limit = 500;
    var page = 1;
    var totalPages = 1;
    final items = <ChapterListItem>[];

    while (page <= totalPages) {
      final res = await client.dio.get(
        '/api/truyen/$idOrSlug/chapters',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = res.data as Map<String, dynamic>;
      final chapters = data['chapters'] as List? ?? const [];

      items.addAll(
        chapters.map(
          (e) => ChapterListItem.fromJson(e as Map<String, dynamic>),
        ),
      );

      final apiTotalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      totalPages = apiTotalPages > 0 ? apiTotalPages : 1;
      page += 1;
    }

    return items;
  }

  try {
    if (!await connectivity.checkIsOnline()) {
      if (cached.isNotEmpty) return;
      throw Exception('Không có mạng và chưa lưu mục lục truyện này');
    }
    var id = canonicalId;
    // Resolve uncached slugs before paging; an empty response is not an error.
    if (localNovel == null) {
      final response = await client.dio.get('/api/novels/$novelId');
      final novel = NovelModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      await novelsRepo.saveNovelDetail(novel);
      id = novel.id;
    }
    final chapters = await fetchAllChapters(id);
    await chaptersRepo.saveMeta(id, chapters);
    yield chapters;
  } catch (_) {
    if (cached.isEmpty) rethrow;
  }
});
