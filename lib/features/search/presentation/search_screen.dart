import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/novel_model.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../novel/providers/novels_provider.dart';
import '../../genres/providers/genres_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialGenre,
    this.initialStatus,
    this.initialSort = 'latest',
  });

  final String? initialQuery;
  final String? initialGenre;
  final String? initialStatus;
  final String initialSort;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _selectedGenre;
  String? _selectedStatus;
  String _sort = 'latest';

  final _statuses = const [
    ('Đang ra', 'ongoing'),
    ('Đã hoàn thành', 'completed'),
    ('Tạm dừng', 'hiatus'),
  ];
  final _sorts = const [
    ('Mới nhất', 'latest'),
    ('Phổ biến', 'popular'),
    ('Đánh giá', 'rating'),
    ('Tên A-Z', 'name'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _syncFromInitialParams(applyImmediately: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyFilters();
    });
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasRouteFilterChange = oldWidget.initialQuery != widget.initialQuery ||
        oldWidget.initialGenre != widget.initialGenre ||
        oldWidget.initialStatus != widget.initialStatus ||
        oldWidget.initialSort != widget.initialSort;
    if (hasRouteFilterChange) {
      _syncFromInitialParams(applyImmediately: true);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(novelsProvider.notifier).loadNextPage();
    }
  }

  void _syncFromInitialParams({required bool applyImmediately}) {
    final incomingQuery = widget.initialQuery?.trim();
    _controller.text = incomingQuery == null || incomingQuery.isEmpty ? '' : incomingQuery;
    _selectedGenre = widget.initialGenre;
    _selectedStatus = widget.initialStatus;
    _sort = widget.initialSort;
    if (applyImmediately) {
      if (mounted) {
        setState(() {});
      }
      _applyFilters();
    }
  }

  void _onQueryChanged(String value) {
    setState(() {}); // refresh clear button visibility
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _applyFilters);
  }

  void _applyFilters() {
    ref.read(novelsProvider.notifier).updateParams(
          BrowseParams(
            query: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
            genre: _selectedGenre,
            status: _selectedStatus,
            sort: _sort,
          ),
        );
  }

  bool get _hasActiveFilters => _selectedGenre != null || _selectedStatus != null || _sort != 'latest';

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresListProvider);
    ref.watch(genresSyncProvider);
    final novelsAsync = ref.watch(novelsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _controller,
              autofocus: widget.initialQuery == null,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Tên truyện, tác giả...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          _applyFilters();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                genresAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, error) => const SizedBox.shrink(),
                  data: (genres) => _FilterChipDropdown(
                    label: _selectedGenre == null
                        ? 'Thể loại'
                        : genres.firstWhere((g) => g.slug == _selectedGenre, orElse: () => genres.first).name,
                    selected: _selectedGenre != null,
                    items: genres
                        .map((g) => PopupMenuItem(value: g.slug, child: Text(g.name)))
                        .toList(),
                    onSelected: (v) {
                      setState(() => _selectedGenre = _selectedGenre == v ? null : v);
                      _applyFilters();
                    },
                    onClear: () {
                      setState(() => _selectedGenre = null);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipDropdown(
                  label: _selectedStatus == null
                      ? 'Trạng thái'
                      : _statuses.firstWhere((s) => s.$2 == _selectedStatus, orElse: () => _statuses.first).$1,
                  selected: _selectedStatus != null,
                  items: _statuses
                      .map((s) => PopupMenuItem(value: s.$2, child: Text(s.$1)))
                      .toList(),
                  onSelected: (v) {
                    setState(() => _selectedStatus = _selectedStatus == v ? null : v);
                    _applyFilters();
                  },
                  onClear: () {
                    setState(() => _selectedStatus = null);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipDropdown(
                  label: _sorts.firstWhere((s) => s.$2 == _sort).$1,
                  selected: _sort != 'latest',
                  items: _sorts
                      .map((s) => PopupMenuItem(value: s.$2, child: Text(s.$1)))
                      .toList(),
                  onSelected: (v) {
                    if (v != null) {
                      setState(() => _sort = v);
                      _applyFilters();
                    }
                  },
                  onClear: null,
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedGenre = null;
                        _selectedStatus = null;
                        _sort = 'latest';
                      });
                      _applyFilters();
                    },
                    child: const Text('Xoá lọc'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: novelsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: 6,
                itemBuilder: (context, index) => const _SearchTileSkeleton(),
              ),
              error: (e, _) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Không thể tải kết quả',
                subtitle: '$e',
                actionLabel: 'Thử lại',
                onAction: _applyFilters,
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Không tìm thấy truyện',
                    subtitle: 'Thử từ khoá khác hoặc bỏ bớt bộ lọc',
                  );
                }
                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
                  itemCount: result.items.length + (result.hasMore || result.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index >= result.items.length) {
                      if (result.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        ref.read(novelsProvider.notifier).loadNextPage();
                      });
                      return const SizedBox(height: 32);
                    }
                    return _NovelResultTile(novel: result.items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
    );
  }
}

class _FilterChipDropdown extends StatelessWidget {
  final String label;
  final bool selected;
  final List<PopupMenuEntry<String>> items;
  final void Function(String?)? onSelected;
  final VoidCallback? onClear;

  const _FilterChipDropdown({
    required this.label,
    required this.selected,
    required this.items,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: IgnorePointer(
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {},
          deleteIcon: selected && onClear != null ? const Icon(Icons.close, size: 14) : null,
          onDeleted: selected ? onClear : null,
        ),
      ),
    );
  }
}

class _NovelResultTile extends StatelessWidget {
  final NovelModel novel;
  const _NovelResultTile({required this.novel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = novel.status.toLowerCase().contains('hoàn');

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(RouteNames.novelDetail(novel.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: novel.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: novel.coverUrl!,
                      width: 56,
                      height: 76,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 76,
                      color: colorScheme.primaryContainer,
                      child: const Icon(Icons.menu_book, size: 20),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    novel.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      StatusPill(
                        label: novel.status,
                        tone: isCompleted ? StatusPillTone.success : StatusPillTone.neutral,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (novel.rating > 0) ...[
                        Icon(Icons.star_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          novel.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
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

class _SearchTileSkeleton extends StatelessWidget {
  const _SearchTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerLow;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 76,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
