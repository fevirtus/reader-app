import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_names.dart';
import '../../../core/models/novel_model.dart';
import '../../../shared/widgets/book_cover.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/main_app_header.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(homeDataProvider);
    final sync = ref.watch(homeSyncProvider);
    return Scaffold(
      body: Column(
        children: [
          const MainAppHeader(subtitle: 'Một câu chuyện hay đang chờ bạn.'),
          Expanded(
            child: data.isEmpty && sync.isLoading
                ? const SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: SkeletonBox(height: 220),
                        ),
                        SkeletonNovelRow(),
                      ],
                    ),
                  )
                : data.isEmpty && sync.hasError
                ? EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Chưa tải được thư viện',
                    subtitle: 'Kiểm tra kết nối mạng rồi thử lại nhé.',
                    actionLabel: 'Thử lại',
                    onAction: () =>
                        ref.read(homeSyncProvider.notifier).refresh(),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(homeSyncProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 28),
                      children: [
                        if (data.hot.isNotEmpty)
                          _FeaturedBook(novel: data.hot.first),
                        const SizedBox(height: 20),
                        const _QuickFilters(),
                        SectionHeader(
                          title: 'Mới trên kệ sách',
                          onMore: () => context.go(RouteNames.search),
                        ),
                        _BookShelf(novels: data.latest),
                        SectionHeader(
                          title: 'Được yêu thích',
                          onMore: () =>
                              context.go('${RouteNames.search}?sort=rating'),
                        ),
                        ...data.topRated
                            .take(5)
                            .indexed
                            .map(
                              (entry) => _RankedBook(
                                novel: entry.$2,
                                rank: entry.$1 + 1,
                              ),
                            ),
                        SectionHeader(
                          title: 'Đọc nhiều nhất',
                          onMore: () =>
                              context.go('${RouteNames.search}?sort=popular'),
                        ),
                        _BookShelf(novels: data.topViews),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedBook extends StatelessWidget {
  const _FeaturedBook({required this.novel});
  final NovelModel novel;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final dark = t.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: dark ? const Color(0xFF263C31) : const Color(0xFFE5EDE4),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(RouteNames.novelDetail(novel.id)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NỔI BẬT HÔM NAY',
                        style: t.textTheme.labelSmall?.copyWith(
                          color: t.colorScheme.primary,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        novel.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.headlineSmall?.copyWith(
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        novel.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall?.copyWith(
                          color: t.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Khám phá ngay',
                              style: t.textTheme.labelLarge?.copyWith(
                                color: t.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: t.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                BookCover(url: novel.coverUrl, width: 105, height: 157),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickFilters extends StatelessWidget {
  const _QuickFilters();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      (Icons.auto_stories_outlined, 'Mới cập nhật', RouteNames.search),
      (
        Icons.trending_up_rounded,
        'Đọc nhiều',
        '${RouteNames.search}?sort=popular',
      ),
      (
        Icons.star_outline_rounded,
        'Đánh giá cao',
        '${RouteNames.search}?sort=rating',
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(item.$1, size: 18, color: cs.primary),
                  label: Text(item.$2),
                  backgroundColor: cs.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  onPressed: () => context.go(item.$3),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BookShelf extends StatelessWidget {
  const _BookShelf({required this.novels});
  final List<NovelModel> novels;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final extra = (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
      0,
      36,
    );
    return SizedBox(
      height: 286 + extra * 5,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: novels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final n = novels[i];
          return SizedBox(
            width: 126,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.push(RouteNames.novelDetail(n.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(url: n.coverUrl, width: 126, height: 180),
                  const SizedBox(height: 12),
                  Text(
                    n.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${n.totalChapters} chương',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall?.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RankedBook extends StatelessWidget {
  const _RankedBook({required this.novel, required this.rank});
  final NovelModel novel;
  final int rank;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Material(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(RouteNames.novelDetail(novel.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$rank'.padLeft(2, '0'),
                    style: t.textTheme.titleMedium?.copyWith(
                      color: t.colorScheme.primary,
                    ),
                  ),
                ),
                BookCover(url: novel.coverUrl, width: 52, height: 76),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        novel.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        novel.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall?.copyWith(
                          color: t.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        novel.ratingCount > 0
                            ? '★ ${novel.rating.toStringAsFixed(1)}/10 · ${novel.totalChapters} chương'
                            : '${novel.totalChapters} chương',
                        style: t.textTheme.labelSmall?.copyWith(
                          color: t.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
