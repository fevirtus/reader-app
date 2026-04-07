import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/novel_model.dart';
import '../../../core/storage/local_store.dart';
import '../../bookshelf/providers/bookshelf_provider.dart';
import '../providers/novels_provider.dart';

final novelReadProgressProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, novelId) async {
  final localStore = ref.read(localStoreProvider);
  return localStore.loadProgress(novelId);
});

class NovelDetailScreen extends ConsumerStatefulWidget {
  const NovelDetailScreen({super.key, required this.novelId});

  final String novelId;

  @override
  ConsumerState<NovelDetailScreen> createState() => _NovelDetailScreenState();
}

class _NovelDetailScreenState extends ConsumerState<NovelDetailScreen> {
  int _currentPage = 1;

  @override
  void didUpdateWidget(covariant NovelDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.novelId != widget.novelId && _currentPage != 1) {
      setState(() => _currentPage = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final novelId = widget.novelId;
    final novelAsync = ref.watch(novelDetailProvider(novelId));
    final chaptersAsync = ref.watch(
      chapterListProvider(ChapterListQuery(novelId: novelId, page: _currentPage)),
    );
    final firstChapterAsync = ref.watch(
      chapterListProvider(ChapterListQuery(novelId: novelId, page: 1)),
    );
    final readProgressAsync = ref.watch(novelReadProgressProvider(novelId));
    final isBookmarked = ref.watch(isBookmarkedProvider(novelId));

    return Scaffold(
      body: novelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (novel) => CustomScrollView(
          slivers: [
            _NovelAppBar(novel: novel, isBookmarked: isBookmarked, onBookmark: () {
              ref.read(bookshelfProvider.notifier).toggle(novelId);
            }),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genre chips
                    if (novel.genres.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: novel.genres
                            .map((g) => Chip(
                                  label: Text(g.name),
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    // Description
                    if (novel.description != null)
                      Text(novel.description!, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    // Stats row
                    _StatsRow(novel: novel),
                    const SizedBox(height: 16),
                    // Read button
                    firstChapterAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (firstPage) {
                        final first =
                            firstPage.chapters.isNotEmpty ? firstPage.chapters.first : null;
                        if (first == null) return const SizedBox.shrink();

                        final progress = readProgressAsync.valueOrNull;
                        final continueChapterId = progress?['chapterId'] as String?;
                        final continueChapterNumber =
                            (progress?['chapterNumber'] as num?)?.toInt();
                        final hasProgress = continueChapterId != null && continueChapterId.isNotEmpty;
                        final targetChapterId = hasProgress ? continueChapterId : first.id;
                        final buttonLabel = hasProgress
                            ? 'Đọc tiếp chương ${continueChapterNumber ?? '?'}'
                            : 'Đọc từ đầu';

                        return FilledButton.icon(
                          onPressed: () => context.push(
                            RouteNames.readerChapter(targetChapterId),
                          ),
                          icon: const Icon(Icons.menu_book),
                          label: Text(buttonLabel),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Chapter list header
                    Row(
                      children: [
                        Text('Danh sách chương', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        chaptersAsync.whenOrNull(
                          data: (pageData) => Text(
                            '${pageData.totalChapters} chương • Trang ${pageData.currentPage}/${pageData.totalPages == 0 ? 1 : pageData.totalPages}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ) ?? const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Chapter list
            chaptersAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Không tải được danh sách chương: $error',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              data: (pageData) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ch = pageData.chapters[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        'Chương ${ch.number}: ${ch.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => context.push(RouteNames.readerChapter(ch.id)),
                    );
                  },
                  childCount: pageData.chapters.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: chaptersAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (pageData) {
                  final totalPages = pageData.totalPages == 0 ? 1 : pageData.totalPages;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage = _currentPage - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Trang trước'),
                        ),
                        const Spacer(),
                        Text('Trang $_currentPage/$totalPages'),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _currentPage < totalPages
                              ? () => setState(() => _currentPage = _currentPage + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Trang sau'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _NovelAppBar extends StatelessWidget {
  final NovelModel novel;
  final bool isBookmarked;
  final VoidCallback onBookmark;

  const _NovelAppBar({
    required this.novel,
    required this.isBookmarked,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      actions: [
        IconButton(
          icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
          onPressed: onBookmark,
        ),
        IconButton(
          icon: const Icon(Icons.comment_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Bình luận')),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (novel.coverUrl != null)
              CachedNetworkImage(
                imageUrl: novel.coverUrl!,
                fit: BoxFit.cover,
              )
            else
              Container(color: Theme.of(context).colorScheme.primaryContainer),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(200)],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (novel.authorName.isNotEmpty)
                    Text(
                      novel.authorName,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final NovelModel novel;
  const _StatsRow({required this.novel});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (novel.rating > 0)
          _Stat(icon: Icons.star, value: novel.rating.toStringAsFixed(1)),
        if (novel.views > 0)
          _Stat(icon: Icons.visibility, value: _formatNum(novel.views)),
        if (novel.latestChapter != null)
          _Stat(icon: Icons.library_books, value: 'Ch. ${novel.latestChapter!.number}'),
      ],
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _Stat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 4),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
