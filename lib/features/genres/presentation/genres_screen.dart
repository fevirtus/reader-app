import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/main_app_header.dart';
import '../providers/genres_provider.dart';

class GenresScreen extends ConsumerStatefulWidget {
  const GenresScreen({super.key});
  @override
  ConsumerState<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends ConsumerState<GenresScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final all = ref.watch(genresListProvider).valueOrNull ?? const [];
    final sync = ref.watch(genresSyncProvider);
    final genres = all
        .where(
          (g) => g.name.toLowerCase().contains(_query.toLowerCase().trim()),
        )
        .toList();
    final t = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          const MainAppHeader(
            title: 'Thể loại',
            subtitle: 'Tìm thế giới mà bạn muốn bước vào.',
            showSearch: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Tìm thể loại…',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  '${genres.length} thể loại',
                  style: t.textTheme.labelLarge?.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: all.isEmpty && sync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : all.isEmpty && sync.hasError
                ? EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Chưa tải được thể loại',
                    actionLabel: 'Thử lại',
                    onAction: () =>
                        ref.read(genresSyncProvider.notifier).refresh(),
                  )
                : genres.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Không có thể loại phù hợp',
                    subtitle: 'Thử tìm bằng một từ khác nhé.',
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(genresSyncProvider.notifier).refresh(),
                    child: LayoutBuilder(
                      builder: (context, constraints) => GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              constraints.maxWidth < 340 ||
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      20
                              ? 1
                              : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 122,
                        ),
                        itemCount: genres.length,
                        itemBuilder: (context, index) {
                          final genre = genres[index];
                          return Material(
                            color: t.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: t.colorScheme.outlineVariant,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => context.go(
                                '${RouteNames.search}?genre=${Uri.encodeQueryComponent(genre.slug)}',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.auto_stories_outlined,
                                          size: 22,
                                          color: t.colorScheme.primary,
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.north_east_rounded,
                                          size: 16,
                                          color: t.colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      genre.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${genre.novelCount} truyện',
                                      style: t.textTheme.bodySmall?.copyWith(
                                        color: t.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
