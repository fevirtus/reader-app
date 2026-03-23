import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/bookmark_model.dart';
import '../providers/bookshelf_provider.dart';
import '../../auth/providers/auth_provider.dart';

class BookshelfScreen extends ConsumerWidget {
  const BookshelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(isAuthenticatedProvider);

    if (!isAuth) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tủ sách')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              const Text('Vui lòng đăng nhập để xem tủ sách'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(RouteNames.login),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }

    final bookshelfAsync = ref.watch(bookshelfProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tủ sách'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(bookshelfProvider.notifier).fetch(),
          ),
        ],
      ),
      body: bookshelfAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text('Lỗi: $e'),
              TextButton(
                onPressed: () => ref.read(bookshelfProvider.notifier).fetch(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined, size: 56),
                  SizedBox(height: 12),
                  Text('Chưa có truyện nào trong tủ sách'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(bookshelfProvider.notifier).fetch(),
            child: ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) =>
                  _BookmarkTile(bookmark: bookmarks[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final BookmarkModel bookmark;
  const _BookmarkTile({required this.bookmark});

  @override
  Widget build(BuildContext context) {
    final novel = bookmark.novel;
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: novel?.coverUrl != null
            ? CachedNetworkImage(
                imageUrl: novel!.coverUrl!,
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
      title: Text(
        novel?.title ?? bookmark.novelId,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: novel?.authorName != null
          ? Text(novel!.authorName, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      onTap: () => context.push(RouteNames.novelDetail(bookmark.novelId)),
    );
  }
}
