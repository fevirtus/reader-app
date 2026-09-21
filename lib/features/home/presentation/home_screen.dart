import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/novel_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    Widget body;
    if (data.isEmpty && sync.isLoading) {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.xl),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SkeletonBox(height: 220, borderRadius: AppRadius.lg),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonNovelRow(),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonNovelRow(),
        ],
      );
    } else if (data.isEmpty && sync.hasError) {
      body = EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Không thể tải dữ liệu trang chủ',
        subtitle: sync.error.toString(),
        actionLabel: 'Tải lại',
        onAction: () => ref.read(homeSyncProvider.notifier).refresh(),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => ref.read(homeSyncProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.xl),
          children: [
            _HotCarousel(novels: data.hot),
            const SizedBox(height: AppSpacing.md),
            const _HomeQuickFilters(),
            SectionHeader(
              title: 'Truyện mới nhất',
              onMore: () => context.go(RouteNames.search),
            ),
            _NovelHorizontalList(novels: data.latest),
            SectionHeader(
              title: 'Xếp hạng đánh giá',
              onMore: () => context.go('${RouteNames.search}?sort=rating'),
            ),
            _FeatureGrid(novels: data.topRated.take(6).toList(), metricLabel: 'đánh giá'),
            SectionHeader(
              title: 'Xếp hạng lượt đọc',
              onMore: () => context.go('${RouteNames.search}?sort=popular'),
            ),
            _FeatureGrid(novels: data.topViews.take(6).toList(), metricLabel: 'lượt đọc'),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const MainAppHeader(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _HomeQuickFilters extends StatelessWidget {
  const _HomeQuickFilters();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.dashboard_customize_rounded, 'Thể loại'),
      (Icons.verified_rounded, 'Hoàn thành'),
      (Icons.sell_rounded, 'Miễn phí'),
      (Icons.local_fire_department_rounded, 'Truyện hot'),
    ];
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Column(
                  children: [
                    Icon(item.$1, color: accent, size: 26),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accent),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _HotCarousel extends StatefulWidget {
  final List<NovelModel> novels;
  const _HotCarousel({required this.novels});

  @override
  State<_HotCarousel> createState() => _HotCarouselState();
}

class _HotCarouselState extends State<_HotCarousel> {
  late PageController _controller;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1);
    _startAutoSlide();
  }

  @override
  void reassemble() {
    super.reassemble();
    _recreateController();
  }

  void _recreateController() {
    final oldController = _controller;
    final page = oldController.hasClients
        ? (oldController.page?.round() ?? _currentPage)
        : _currentPage;
    _controller = PageController(initialPage: page, viewportFraction: 1);
    oldController.dispose();
  }

  @override
  void didUpdateWidget(covariant _HotCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.novels.length != widget.novels.length) {
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (widget.novels.length <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.novels.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.novels.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 260,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: ClipRect(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: widget.novels.length,
                    onPageChanged: (value) => setState(() => _currentPage = value),
                    itemBuilder: (context, index) {
                      final novel = widget.novels[index];
                      return GestureDetector(
                        onTap: () => context.push(RouteNames.novelDetail(novel.id)),
                        child: _CarouselCard(novel: novel),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.novels.length.clamp(0, 5), (index) {
              final active = index == _currentPage.clamp(0, 4);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? accent : Colors.white54,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final NovelModel novel;
  const _CarouselCard({required this.novel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (novel.coverUrl != null)
          CachedNetworkImage(
            imageUrl: novel.coverUrl!,
            fit: BoxFit.cover,
            placeholder: (_, imageUrl) => Container(color: Colors.grey[200]),
            errorWidget: (_, imageUrl, error) => Container(color: Colors.grey[300]),
          )
        else
          Container(color: Theme.of(context).colorScheme.primaryContainer),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withAlpha(180)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: AppSpacing.md,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (novel.status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightSuccess,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    novel.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                novel.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                novel.description?.trim().isNotEmpty == true
                    ? novel.description!.trim()
                    : novel.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NovelHorizontalList extends StatelessWidget {
  final List<NovelModel> novels;
  const _NovelHorizontalList({required this.novels});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 226,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: novels.length,
        separatorBuilder: (_, separatorIndex) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final novel = novels[index];
          return GestureDetector(
            onTap: () => context.push(RouteNames.novelDetail(novel.id)),
            child: SizedBox(
              width: 122,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: novel.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: novel.coverUrl!,
                            width: 122,
                            height: 155,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 122,
                            height: 155,
                            color: colorScheme.primaryContainer,
                            child: const Icon(Icons.menu_book),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      novel.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    novel.latestChapter != null
                        ? 'Chương ${novel.latestChapter!.number}'
                        : '${novel.totalChapters} chương',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.novels, required this.metricLabel});

  final List<NovelModel> novels;
  final String metricLabel;

  @override
  Widget build(BuildContext context) {
    if (novels.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: novels.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.xl,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.74,
        ),
        itemBuilder: (context, index) {
          final novel = novels[index];
          return GestureDetector(
            onTap: () => context.push(RouteNames.novelDetail(novel.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: novel.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: novel.coverUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: colorScheme.primaryContainer,
                            child: const Center(child: Icon(Icons.menu_book_rounded)),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  novel.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${novel.totalChapters} Chương',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  metricLabel == 'đánh giá'
                      ? '${novel.rating.toStringAsFixed(1)}/10'
                      : '${novel.views} lượt đọc',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
