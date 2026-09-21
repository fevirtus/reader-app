import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/bookmark_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/main_app_header.dart';
import '../../downloads/presentation/downloads_tab.dart';
import '../../novel/providers/novels_provider.dart';
import '../providers/bookshelf_provider.dart';
import '../../auth/providers/auth_provider.dart';

class BookshelfScreen extends ConsumerWidget {
  const BookshelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(isAuthenticatedProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // "Đã tải" là dữ liệu cục bộ trên máy, không cần đăng nhập để xem/quản lý —
    // nên tab bar luôn hiển thị, chỉ 2 tab đầu (gắn với tài khoản) mới yêu cầu đăng nhập.
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            MainAppHeader(
              title: 'Đăng truyện',
              bottom: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                ),
                child: TabBar(
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 2.5,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  dividerColor: Colors.transparent,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: Theme.of(context).textTheme.titleSmall,
                  unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
                  tabs: const [
                    Tab(text: 'Đang đọc'),
                    Tab(text: 'Đã đọc'),
                    Tab(text: 'Đã tải'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AuthGatedBookshelfList(
                    isAuth: isAuth,
                    shelfStatus: ShelfStatus.reading,
                  ),
                  _AuthGatedBookshelfList(
                    isAuth: isAuth,
                    shelfStatus: ShelfStatus.completed,
                  ),
                  const DownloadsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthGatedBookshelfList extends ConsumerWidget {
  const _AuthGatedBookshelfList({required this.isAuth, required this.shelfStatus});

  final bool isAuth;
  final ShelfStatus shelfStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isAuth) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Vui lòng đăng nhập để xem tủ sách',
        actionLabel: 'Đăng nhập bằng Google',
        onAction: () => ref.read(authProvider.notifier).signInWithGoogle(),
      );
    }

    final bookshelfAsync = ref.watch(bookshelfProvider);

    return bookshelfAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Lỗi: $e',
        actionLabel: 'Thử lại',
        onAction: () => ref.read(bookshelfProvider.notifier).fetch(),
      ),
      data: (_) {
        final items = shelfStatus == ShelfStatus.reading
            ? ref.watch(readingBookmarksProvider)
            : ref.watch(completedBookmarksProvider);

        return _BookshelfList(
          bookmarks: items,
          emptyLabel: shelfStatus == ShelfStatus.reading
              ? 'Chưa có truyện đang đọc.'
              : 'Chưa có truyện đã đọc xong.',
          continueLabel: shelfStatus == ShelfStatus.reading ? 'Đọc tiếp' : 'Đã đọc',
          showContinueButton: shelfStatus == ShelfStatus.reading,
        );
      },
    );
  }
}

class _BookshelfList extends ConsumerWidget {
  const _BookshelfList({
    required this.bookmarks,
    required this.emptyLabel,
    required this.continueLabel,
    required this.showContinueButton,
  });

  final List<BookmarkModel> bookmarks;
  final String emptyLabel;
  final String continueLabel;
  final bool showContinueButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookmarks.isEmpty) {
      return EmptyState(icon: Icons.menu_book_outlined, title: emptyLabel);
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
            continueLabel: continueLabel,
            showContinueButton: showContinueButton,
            onRemove: () => ref
                .read(bookshelfProvider.notifier)
                .removeFromShelf(bookmark.novelId),
          );
        },
      ),
    );
  }
}

class _BookmarkTile extends ConsumerWidget {
  final BookmarkModel bookmark;
  final String continueLabel;
  final bool showContinueButton;
  final VoidCallback onRemove;
  const _BookmarkTile({
    required this.bookmark,
    required this.continueLabel,
    required this.showContinueButton,
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
                    if (bookmark.shelfStatus == ShelfStatus.completed) ...[
                      const SizedBox(height: 6),
                      Text(
                        bookmark.markedAsRead
                            ? 'Đánh dấu đã đọc'
                            : 'Đã đọc ${novel?.totalChapters ?? bookmark.lastChapterNumber} chương',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ] else if (bookmark.lastChapterNumber != null) ...[
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
          if (showContinueButton) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openContinueReader(context, ref),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(continueLabel),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: null,
                    child: Text(continueLabel),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
}
