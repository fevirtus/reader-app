import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/novel_model.dart';
import '../../../shared/widgets/main_app_header.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const MainAppHeader(),
          Expanded(
            child: homeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 52),
                      const SizedBox(height: 12),
                      Text('Không thể tải dữ liệu trang chủ'),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(homeProvider),
                        child: const Text('Tải lại'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(homeProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                  children: [
                    _HotCarousel(novels: data.hot),
                    const SizedBox(height: 12),
                    const _HomeQuickFilters(),
                    _SectionHeader(
                      title: 'Truyện mới nhất',
                      onMore: () => context.go(RouteNames.search),
                    ),
                    _NovelHorizontalList(novels: data.latest),
                    _SectionHeader(
                      title: 'Xếp hạng đánh giá',
                      onMore: () => context.go('${RouteNames.search}?sort=rating'),
                    ),
                    _FeatureGrid(novels: data.topRated.take(6).toList(), metricLabel: 'đánh giá'),
                    _SectionHeader(
                      title: 'Xếp hạng lượt đọc',
                      onMore: () => context.go('${RouteNames.search}?sort=popular'),
                    ),
                    _FeatureGrid(novels: data.topViews.take(6).toList(), metricLabel: 'lượt đọc'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;

  const _SectionHeader({required this.title, this.onMore});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 12, 6),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            if (onMore != null)
              InkWell(
                onTap: onMore,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Xem thêm',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: const Color(0xFF14B8A6),
                            ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF14B8A6)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Column(
                  children: [
                    Icon(item.$1, color: const Color(0xFF14B8A6), size: 26),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF14B8A6),
                          ),
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
    return SizedBox(
      height: 260,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 8),
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
                  color: active ? const Color(0xFF14B8A6) : Colors.white54,
                  borderRadius: BorderRadius.circular(99),
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
          bottom: 12,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (novel.status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(999),
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
              const SizedBox(height: 10),
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
    return SizedBox(
      height: 226,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: novels.length,
        separatorBuilder: (_, separatorIndex) => const SizedBox(width: 12),
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
                    borderRadius: BorderRadius.circular(10),
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
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.menu_book),
                          ),
                  ),
                  const SizedBox(height: 6),
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
                          color: const Color(0xFF58D68D),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: novels.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 18,
          crossAxisSpacing: 14,
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
                    borderRadius: BorderRadius.circular(10),
                    child: novel.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: novel.coverUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: const Center(child: Icon(Icons.menu_book_rounded)),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
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
                        color: const Color(0xFF58D68D),
                      ),
                ),
                Text(
                  metricLabel == 'đánh giá'
                      ? '${novel.rating.toStringAsFixed(1)}/10'
                      : '${novel.views} lượt đọc',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1677FF),
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

