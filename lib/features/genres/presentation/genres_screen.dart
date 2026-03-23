import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/novel_model.dart';
import '../providers/genres_provider.dart';

class GenresScreen extends ConsumerWidget {
  const GenresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thể loại')),
      body: genresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text('Lỗi tải thể loại'),
              TextButton(
                onPressed: () => ref.invalidate(genresProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (genres) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            final genre = genres[index];
            return _GenreCard(genre: genre);
          },
        ),
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final GenreModel genre;
  const _GenreCard({required this.genre});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('${RouteNames.search}?genre=${genre.slug}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                genre.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (genre.novelCount > 0)
                Text(
                  '${genre.novelCount} truyện',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
