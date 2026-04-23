import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/bookmark_model.dart';
import '../../../shared/widgets/main_app_header.dart';
import '../../novel/providers/novels_provider.dart';
import '../providers/bookshelf_provider.dart';
import '../../auth/providers/auth_provider.dart';

class BookshelfScreen extends ConsumerWidget {
  const BookshelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(isAuthenticatedProvider);

    if (!isAuth) {
      return Scaffold(
        body: Column(
          children: [
            const MainAppHeader(title: 'Đăng truyện'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 54),
                      const SizedBox(height: 12),
                      const Text('Vui lòng đăng nhập để xem tủ sách'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                        child: const Text('Đăng nhập bằng Google'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bookshelfAsync = ref.watch(bookshelfProvider);

    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            MainAppHeader(
              title: 'Đăng truyện',
              bottom: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: TabBar(
                  indicatorColor: const Color(0xFFF7B500),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Đang đọc'),
                    Tab(text: 'Đánh dấu'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: bookshelfAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48),
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
                  final readingItems = ref.watch(readingBookmarksProvider);
                  final bookmarkedItems = ref.watch(savedBookmarksProvider);

                  return TabBarView(
                    children: [
                      _BookshelfList(
                        bookmarks: readingItems,
                        emptyLabel: 'Chưa có truyện đang đọc.',
                      ),
                      _BookshelfList(
                        bookmarks: bookmarkedItems,
                        emptyLabel: 'Chưa có truyện đánh dấu.',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookshelfList extends ConsumerWidget {
  const _BookshelfList({required this.bookmarks, required this.emptyLabel});

  final List<BookmarkModel> bookmarks;
  final String emptyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 56),
            const SizedBox(height: 12),
            Text(emptyLabel),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bookshelfProvider.notifier).fetch(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: bookmarks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final bookmark = bookmarks[index];
          return _BookmarkTile(
            bookmark: bookmark,
            onRemove: () => ref
                .read(bookshelfProvider.notifier)
                .removeFromShelf(bookmark.novelId, bookmark.type),
          );
        },
      ),
    );
  }
}

class _BookmarkTile extends ConsumerWidget {
  final BookmarkModel bookmark;
  final VoidCallback onRemove;
  const _BookmarkTile({
    required this.bookmark,
    required this.onRemove,
  });

  Future<void> _openContinueReader(BuildContext context, WidgetRef ref) async {
    var targetChapterId = bookmark.lastChapterId;
    if (targetChapterId == null || targetChapterId.isEmpty) {
      try {
        final chapters = await ref.read(
          chapterListProvider(bookmark.novelId).future,
        );
        if (chapters.isNotEmpty) {
          targetChapterId = chapters.first.id;
        }
      } catch (_) {
        // Fall through to novel detail when chapter lookup fails.
      }
    }

    if (!context.mounted) return;
    if (targetChapterId != null && targetChapterId.isNotEmpty) {
      context.push(RouteNames.readerChapter(targetChapterId));
      return;
    }
    context.push(RouteNames.novelDetail(bookmark.novelId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novel = bookmark.novel;
    return GestureDetector(
      onTap: () => context.push(RouteNames.novelDetail(bookmark.novelId)),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: novel?.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: novel!.coverUrl!,
                        width: 92,
                        height: 126,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 92,
                        height: 126,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.menu_book, size: 28),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            novel?.title ?? bookmark.novelId,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onRemove,
                            child: const Icon(Icons.close_rounded, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Số chương: ${novel?.totalChapters ?? '--'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (bookmark.lastChapterNumber != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Đang đọc đến: ${bookmark.lastChapterNumber} / ${novel?.totalChapters ?? '--'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (novel?.authorName != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        novel!.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openContinueReader(context, ref),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Đọc tiếp'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
