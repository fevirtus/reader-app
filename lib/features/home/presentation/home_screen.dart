import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/novel_model.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go(RouteNames.search),
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Lỗi tải dữ liệu', style: Theme.of(context).textTheme.bodyLarge),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(homeProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(homeProvider),
          child: ListView(
            children: [
              _HotCarousel(novels: data.hot),
              _SectionHeader(
                title: 'Mới cập nhật',
                onMore: () => context.go(RouteNames.search),
              ),
              _NovelHorizontalList(novels: data.latest),
              _SectionHeader(
                title: 'Đánh giá cao',
                onMore: () => context.go(RouteNames.search),
              ),
              _NovelHorizontalList(novels: data.topRated),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
        padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (onMore != null)
              TextButton(onPressed: onMore, child: const Text('Xem thêm')),
          ],
        ),
      );
}

class _HotCarousel extends StatefulWidget {
  final List<NovelModel> novels;
  const _HotCarousel({required this.novels});

  @override
  State<_HotCarousel> createState() => _HotCarouselState();
}

class _HotCarouselState extends State<_HotCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.novels.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.novels.length,
        itemBuilder: (context, index) {
          final novel = widget.novels[index];
          return GestureDetector(
            onTap: () => context.push(RouteNames.novelDetail(novel.id)),
            child: _CarouselCard(novel: novel),
          );
        },
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final NovelModel novel;
  const _CarouselCard({required this.novel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (novel.coverUrl != null)
              CachedNetworkImage(
                imageUrl: novel.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (_, imageUrl) => Container(color: Colors.grey[200]),
                errorWidget: (_, imageUrl, error) =>
                    Container(color: Colors.grey[300]),
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
              child: Text(
                novel.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovelHorizontalList extends StatelessWidget {
  final List<NovelModel> novels;
  const _NovelHorizontalList({required this.novels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: novels.length,
        separatorBuilder: (_, separatorIndex) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final novel = novels[index];
          return GestureDetector(
            onTap: () => context.push(RouteNames.novelDetail(novel.id)),
            child: SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: novel.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: novel.coverUrl!,
                            width: 110,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 110,
                            height: 150,
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.menu_book),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    novel.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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
