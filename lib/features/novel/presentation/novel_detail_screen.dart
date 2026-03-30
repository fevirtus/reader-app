import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/novel_model.dart';
import '../../bookshelf/providers/bookshelf_provider.dart';
import '../providers/novels_provider.dart';

class NovelDetailScreen extends ConsumerWidget {
  const NovelDetailScreen({super.key, required this.novelId});

  final String novelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelAsync = ref.watch(novelDetailProvider(novelId));
    final chaptersAsync = ref.watch(chapterListProvider(novelId));
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
                    chaptersAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, error) => const SizedBox.shrink(),
                      data: (chapters) {
                        if (chapters.isEmpty) return const SizedBox.shrink();
                        final first = chapters.first;
                        return FilledButton.icon(
                          onPressed: () => context.push(
                            RouteNames.readerChapter(first.id),
                          ),
                          icon: const Icon(Icons.menu_book),
                          label: Text(
                            'Đọc Chương ${first.number}: ${first.title}',
                          ),
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
                          data: (chapters) => Text(
                            '${chapters.length} chương',
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
              error: (_, error) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (chapters) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ch = chapters[index];
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
                  childCount: chapters.length,
                ),
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
