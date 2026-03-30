import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/novel_model.dart';
import '../../novel/providers/novels_provider.dart';
import '../../genres/providers/genres_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
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
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
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

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);
    final novelsAsync = ref.watch(novelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Tên truyện, tác giả...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Genre filter
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
                const SizedBox(width: 8),
                // Status filter
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
                const SizedBox(width: 8),
                // Sort
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: novelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (result) {
                if (result.items.isEmpty) {
                  return const Center(child: Text('Không tìm thấy truyện'));
                }
                return ListView.builder(
                  itemCount: result.items.length,
                  itemBuilder: (context, index) => _NovelListTile(novel: result.items[index]),
                );
              },
            ),
          ),
        ],
      ),
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
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {},
        deleteIcon: selected && onClear != null ? const Icon(Icons.close, size: 14) : null,
        onDeleted: selected ? onClear : null,
      ),
    );
  }
}

class _NovelListTile extends StatelessWidget {
  final NovelModel novel;
  const _NovelListTile({required this.novel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: novel.coverUrl != null
            ? CachedNetworkImage(
                imageUrl: novel.coverUrl!,
                width: 44,
                height: 60,
                fit: BoxFit.cover,
              )
            : Container(
                width: 44,
                height: 60,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.menu_book, size: 20),
              ),
      ),
      title: Text(novel.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        novel.authorName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: novel.rating > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                Text(novel.rating.toStringAsFixed(1)),
              ],
            )
          : null,
      onTap: () => context.push(RouteNames.novelDetail(novel.id)),
    );
  }
}
