import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/bookmark_model.dart';
import '../../../core/models/chapter_model.dart';
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
  static const _kRangeSize = 100;
  static const _kStickyTabHeight = 49.0;
  static const _kStickyChipsHeight = 94.0; // Computed: title(20) + spacer(8) + chips(40) + padding(18) + buffer(8)

  static const _kChapterItemExtent = 48.0; // fixed height per chapter row

  _NovelDetailTab _selectedTab = _NovelDetailTab.intro;
  int _selectedRangeIndex = 0;
  final _scrollController = ScrollController();
  // Anchor placed right before SliverList — always built, never destroyed
  final _chapterListAnchorKey = GlobalKey();
  // First sorted-list index of each range label, used for offset calculation
  final Map<String, int> _rangeFirstIndex = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bookshelfProvider.notifier).fetch();
    });
  }

  @override
  void didUpdateWidget(covariant NovelDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.novelId != widget.novelId) {
      setState(() {
        _selectedTab = _NovelDetailTab.intro;
        _selectedRangeIndex = 0;
        _rangeFirstIndex.clear();
      });
      Future.microtask(() {
        ref.read(bookshelfProvider.notifier).fetch();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final novelId = widget.novelId;
    final novelAsync = ref.watch(novelDetailProvider(novelId));
    final chaptersAsync = ref.watch(chapterListProvider(novelId));
    final readProgressAsync = ref.watch(novelReadProgressProvider(novelId));
    final bookshelfAsync = ref.watch(bookshelfProvider);

    return novelAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Lỗi: $e')),
      ),
      data: (novel) => Scaffold(
        appBar: AppBar(
          title: Text(novel.title, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Info card + read button (scrolls away)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: _NovelInfoCard(novel: novel),
                  ),
                  _buildReadButton(
                    context: context,
                    novelId: novelId,
                    chaptersAsync: chaptersAsync,
                    readProgressAsync: readProgressAsync,
                    bookshelfAsync: bookshelfAsync,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Sticky tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabDelegate(
                height: _kStickyTabHeight,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: _DetailTabs(
                  selectedTab: _selectedTab,
                  onChanged: (tab) {
                    if (tab == _selectedTab) return;
                    setState(() {
                      _selectedTab = tab;
                      if (tab != _NovelDetailTab.chapters) {
                        _selectedRangeIndex = 0;
                      }
                    });
                  },
                ),
              ),
            ),
            // Tab content
            ..._buildContentSlivers(
              context: context,
              novel: novel,
              chaptersAsync: chaptersAsync,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildReadButton({
    required BuildContext context,
    required String novelId,
    required AsyncValue<List<ChapterListItem>> chaptersAsync,
    required AsyncValue<Map<String, dynamic>?> readProgressAsync,
    required AsyncValue<List<BookmarkModel>> bookshelfAsync,
  }) {
    return chaptersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (chapters) {
        final first = chapters.isNotEmpty ? chapters.first : null;
        if (first == null) return const SizedBox.shrink();
        final bookmarks = bookshelfAsync.valueOrNull ?? const <BookmarkModel>[];
        final latestBookmark =
            bookmarks.where((b) => b.novelId == novelId).firstOrNull;
        final progress = readProgressAsync.valueOrNull;
        final continueChapterId =
            latestBookmark?.lastChapterId ?? (progress?['chapterId'] as String?);
        final continueChapterNumber =
            latestBookmark?.lastChapterNumber ??
            (progress?['chapterNumber'] as num?)?.toInt();
        final hasProgress =
            continueChapterId != null && continueChapterId.isNotEmpty;
        final targetChapterId = hasProgress ? continueChapterId : first.id;
        final buttonLabel = hasProgress
            ? 'Đọc tiếp chương ${continueChapterNumber ?? '?'}'
            : 'Đọc từ đầu';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: () =>
                context.push(RouteNames.readerChapter(targetChapterId)),
            icon: const Icon(Icons.menu_book),
            label: Text(buttonLabel),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildContentSlivers({
    required BuildContext context,
    required NovelModel novel,
    required AsyncValue<List<ChapterListItem>> chaptersAsync,
  }) {
    // Non-chapter tabs: simple sliver
    if (_selectedTab != _NovelDetailTab.chapters) {
      final Widget content;
      switch (_selectedTab) {
        case _NovelDetailTab.intro:
          content = Padding(
            padding: const EdgeInsets.all(16),
            child: novel.description != null
                ? Text(novel.description!, style: Theme.of(context).textTheme.bodyMedium)
                : Text('Chưa có giới thiệu', style: Theme.of(context).textTheme.bodyMedium),
          );
        case _NovelDetailTab.ratings:
          content = Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPlaceholderContent(context, 'Đánh giá sẽ được cập nhật sau.'),
          );
        case _NovelDetailTab.comments:
          content = Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPlaceholderContent(context, 'Bình luận sẽ được cập nhật sau.'),
          );
        case _NovelDetailTab.chapters:
          content = const SizedBox.shrink();
      }
      return [SliverToBoxAdapter(child: content)];
    }

    // Chapters tab
    if (chaptersAsync.isLoading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (chaptersAsync.hasError) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Không tải được danh sách chương: ${chaptersAsync.error}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ];
    }

    final sorted = [...(chaptersAsync.valueOrNull ?? <ChapterListItem>[])]
      ..sort((a, b) => a.number.compareTo(b.number));

    if (sorted.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Không có chương nào', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ];
    }

    final ranges = _buildChapterRanges(sorted);
    final selIdx =
        _selectedRangeIndex >= ranges.length ? ranges.length - 1 : _selectedRangeIndex;

    final firstChapterForRange = <String, ChapterListItem>{};
    for (final range in ranges) {
      for (final ch in sorted) {
        if (ch.number >= range.start && ch.number <= range.end) {
          firstChapterForRange[range.label] = ch;
          break;
        }
      }
    }

    final visibleRanges =
        ranges.where((r) => firstChapterForRange.containsKey(r.label)).toList();

    // Build first-index map for offset-based scrolling (no GlobalKey per item needed)
    for (var i = 0; i < sorted.length; i++) {
      final ch = sorted[i];
      for (final e in firstChapterForRange.entries) {
        if (e.value.id == ch.id) {
          _rangeFirstIndex[e.key] = i;
          break;
        }
      }
    }

    return [
      // ── Sticky range chips header ────────────────────────────────────
      SliverPersistentHeader(
        pinned: true,
        delegate: _StickyRangeChipsDelegate(
          visibleRanges: visibleRanges,
          selectedIndex: selIdx,
          totalChapters: sorted.length,
          onSelected: (i) {
            final label = visibleRanges[i].label;
            final firstIndex = _rangeFirstIndex[label] ?? 0;
            setState(() => _selectedRangeIndex = i);
            _scrollToRangeIndex(firstIndex);
          },
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          primaryColor: Theme.of(context).colorScheme.primary,
          outlineColor: Theme.of(context).colorScheme.outline,
          titleStyle: Theme.of(context).textTheme.titleMedium,
          bodySmallStyle: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      // ── Anchor: SliverToBoxAdapter luôn được build, không bị lazy-destroy ──
      SliverToBoxAdapter(
        key: _chapterListAnchorKey,
        child: const SizedBox.shrink(),
      ),
      // ── Full chapter list (fixed extent để tính offset chính xác) ────
      SliverFixedExtentList(
        itemExtent: _kChapterItemExtent,
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ch = sorted[index];
            return InkWell(
              onTap: () => context.push(RouteNames.readerChapter(ch.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  'Chương ${ch.number}: ${ch.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          },
          childCount: sorted.length,
        ),
      ),
    ];
  }

  Future<void> _scrollToRangeIndex(int itemIndex) async {
    // Small delay for setState rebuild to complete
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted || !_scrollController.hasClients) return;

    // Anchor widget (SliverToBoxAdapter) is always built — context never null
    final anchorCtx = _chapterListAnchorKey.currentContext;
    if (anchorCtx == null) {
      debugPrint('[ScrollToRange] Anchor context null — unexpected');
      return;
    }
    final anchorRender = anchorCtx.findRenderObject();
    if (anchorRender == null || !anchorRender.attached) {
      debugPrint('[ScrollToRange] Anchor render object not attached');
      return;
    }

    final viewport = RenderAbstractViewport.of(anchorRender);
    if (viewport == null) {
      debugPrint('[ScrollToRange] No viewport for anchor render object');
      return;
    }

    // Absolute scroll offset where the chapter list starts.
    final anchorOffset = viewport.getOffsetToReveal(anchorRender, 0.0).offset;
    // Keep a small gap below pinned sticky headers inside CustomScrollView body.
    const stickyCompensation = _kStickyTabHeight + _kStickyChipsHeight + 8.0;

    final rawTarget = anchorOffset + itemIndex * _kChapterItemExtent - stickyCompensation;
    final target = rawTarget
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    debugPrint('[ScrollToRange] index=$itemIndex anchorOffset=$anchorOffset target=$target');

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  // ignore: unused_element
  Future<void> _scrollToRange(GlobalKey targetKey, {int retryCount = 0}) async {
    // Delay để rebuild + layout settle
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      debugPrint('[ScrollToRange] Not mounted');
      return;
    }
    if (!_scrollController.hasClients) {
      debugPrint('[ScrollToRange] No scroll clients');
      return;
    }

    final ctx = targetKey.currentContext;
    if (ctx == null) {
      debugPrint('[ScrollToRange] Target context is null (retry: $retryCount)');
      if (retryCount < 3) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return _scrollToRange(targetKey, retryCount: retryCount + 1);
      }
      return;
    }

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) {
      debugPrint('[ScrollToRange] RenderBox is null (retry: $retryCount)');
      if (retryCount < 3) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return _scrollToRange(targetKey, retryCount: retryCount + 1);
      }
      return;
    }

    try {
      // Compute absolute Y of the item on screen
      final itemScreenY = box.localToGlobal(Offset.zero).dy;
      debugPrint('[ScrollToRange] Item screen Y: $itemScreenY');

      // Target Y: just below AppBar + sticky tab bar + sticky chips, with small padding
      const targetScreenY = kToolbarHeight + _kStickyTabHeight + _kStickyChipsHeight + 8.0;
      debugPrint('[ScrollToRange] Target screen Y: $targetScreenY');

      final delta = itemScreenY - targetScreenY;
      final currentOffset = _scrollController.offset;
      final target = (currentOffset + delta).clamp(0.0, _scrollController.position.maxScrollExtent);

      debugPrint('[ScrollToRange] Current offset: $currentOffset, Delta: $delta, Target: $target, Max: ${_scrollController.position.maxScrollExtent}');

      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
      debugPrint('[ScrollToRange] Scroll completed');
    } catch (e) {
      debugPrint('[ScrollToRange] Error: $e');
    }
  }

  List<_ChapterRange> _buildChapterRanges(List<ChapterListItem> chapters) {
    if (chapters.isEmpty) return const [];
    final maxNum = chapters.last.number;
    final ranges = <_ChapterRange>[];
    for (var start = 1; start <= maxNum; start += _kRangeSize) {
      final end = (start + _kRangeSize - 1).clamp(start, maxNum);
      ranges.add(_ChapterRange(start: start, end: end));
    }
    return ranges;
  }

  Widget _buildPlaceholderContent(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

enum _NovelDetailTab { intro, ratings, chapters, comments }

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({required this.selectedTab, required this.onChanged});

  final _NovelDetailTab selectedTab;
  final ValueChanged<_NovelDetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_NovelDetailTab.intro, 'Giới thiệu'),
      (_NovelDetailTab.ratings, 'Đánh giá'),
      (_NovelDetailTab.chapters, 'Chương'),
      (_NovelDetailTab.comments, 'Bình luận'),
    ];

    return Row(
      children: tabs.map((tab) {
        final isSelected = selectedTab == tab.$1;
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(tab.$1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                tab.$2,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChapterRange {
  const _ChapterRange({required this.start, required this.end});

  final int start;
  final int end;

  String get label => '$start-$end';
}

// ── Novel info card ────────────────────────────────────────────────────────────

class _NovelInfoCard extends StatelessWidget {
  const _NovelInfoCard({required this.novel});
  final NovelModel novel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = novel.status.toLowerCase().contains('ho\u00e0n')
        ? Colors.green.shade700
        : colorScheme.tertiary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: novel.coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: novel.coverUrl!,
                  width: 90,
                  height: 130,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder(colorScheme),
                )
              : _placeholder(colorScheme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                novel.title,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (novel.authorName.isNotEmpty)
                Text(
                  novel.authorName,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withAlpha(120)),
                ),
                child: Text(
                  novel.status,
                  style: textTheme.labelSmall?.copyWith(color: statusColor),
                ),
              ),
              const SizedBox(height: 8),
              if (novel.genres.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: novel.genres
                      .take(5)
                      .map((g) => _SmallChip(label: g.name))
                      .toList(),
                ),
              const SizedBox(height: 8),
              DefaultTextStyle(
                style: textTheme.bodySmall!
                    .copyWith(color: colorScheme.onSurfaceVariant),
                child: Wrap(
                  spacing: 12,
                  children: [
                    if (novel.totalChapters > 0)
                      Text('${novel.totalChapters} Ch\u01b0\u01a1ng'),
                    if (novel.views > 0) Text('${_fmt(novel.views)} \u0110\u1ecdc'),
                    if (novel.rating > 0)
                      Text('${novel.rating.toStringAsFixed(1)}\u2605'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        width: 90,
        height: 130,
        color: cs.primaryContainer,
        child: Icon(Icons.book, color: cs.onPrimaryContainer, size: 36),
      );

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _ChapterListItem extends StatelessWidget {
  final ChapterListItem chapter;
  final VoidCallback onTap;

  const _ChapterListItem({
    required this.chapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Chương ${chapter.number}: ${chapter.title}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

// ── Sticky tab bar delegate ────────────────────────────────────────────────────

class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabDelegate({
    required this.child,
    required this.height,
    required this.backgroundColor,
  });

  final Widget child;
  final double height;
  final Color backgroundColor;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: shrinkOffset > 0 ? 2 : 0,
      shadowColor: Theme.of(context).shadowColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabDelegate old) =>
      old.child != child || old.height != height || old.backgroundColor != backgroundColor;
}

// ── Sticky range chips delegate ────────────────────────────────────────────────

class _StickyRangeChipsDelegate extends SliverPersistentHeaderDelegate {
  const _StickyRangeChipsDelegate({
    required this.visibleRanges,
    required this.selectedIndex,
    required this.totalChapters,
    required this.onSelected,
    required this.backgroundColor,
    required this.primaryColor,
    required this.outlineColor,
    required this.titleStyle,
    required this.bodySmallStyle,
  });

  final List<_ChapterRange> visibleRanges;
  final int selectedIndex;
  final int totalChapters;
  final void Function(int) onSelected;
  final Color backgroundColor;
  final Color primaryColor;
  final Color outlineColor;
  final TextStyle? titleStyle;
  final TextStyle? bodySmallStyle;

  @override
  double get minExtent => _computeExtent();
  @override
  double get maxExtent => _computeExtent();

  double _computeExtent() {
    // Estimate dynamically based on typical component heights
    // This avoids hardcoding and adapts to different devices/fonts
    // Title row: ~20px (text + line height)
    // Spacer: 8px
    // Chips row: ~40px (typical FilterChip height)
    // Padding vertical: 10 + 8 = 18px
    // Buffer: 8px for safety across devices
    return 20 + 8 + 40 + 18 + 8; // ~94px (flexible, not hardcoded)
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final extent = _computeExtent();
    return SizedBox(
      height: extent,
      child: Material(
        color: backgroundColor,
        elevation: shrinkOffset > 0 ? 2 : 0,
        shadowColor: Theme.of(context).shadowColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Danh sách chương', style: titleStyle),
                  const Spacer(),
                  Text('$totalChapters chương', style: bodySmallStyle),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(visibleRanges.length, (i) {
                      final range = visibleRanges[i];
                      final isSelected = i == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(range.label),
                          selected: isSelected,
                          onSelected: (_) => onSelected(i),
                          backgroundColor: Colors.transparent,
                          selectedColor: primaryColor.withAlpha(40),
                          side: BorderSide(
                            color: isSelected ? primaryColor : outlineColor,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyRangeChipsDelegate old) =>
      old.selectedIndex != selectedIndex ||
      old.visibleRanges != visibleRanges ||
      old.totalChapters != totalChapters;
}
