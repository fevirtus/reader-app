import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/book_cover.dart';
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
              title: 'Tủ sách',
              subtitle: 'Những câu chuyện bạn đang đồng hành.',
              bottom: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  indicator: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  dividerColor: Colors.transparent,
                  isScrollable: false,
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
  const _AuthGatedBookshelfList({
    required this.isAuth,
    required this.shelfStatus,
  });

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
          continueLabel: shelfStatus == ShelfStatus.reading
              ? 'Đọc tiếp'
              : 'Đã đọc',
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
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
    final t = Theme.of(context);
    final total = novel?.totalChapters ?? 0;
    final current = bookmark.lastChapterNumber ?? 0;
    return Material(
      color: t.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: t.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(RouteNames.novelDetail(bookmark.novelId)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(url: novel?.coverUrl, width: 76, height: 110),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          novel?.title ?? 'Truyện trong tủ sách',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          novel?.authorName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodySmall?.copyWith(
                            color: t.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          bookmark.isCompleted
                              ? 'Đã đọc xong'
                              : 'Chương $current / ${total > 0 ? total : "—"}',
                          style: t.textTheme.labelSmall?.copyWith(
                            color: t.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: bookmark.isCompleted
                              ? 1
                              : total > 0
                              ? (current / total).clamp(0, 1)
                              : 0,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(4),
                          backgroundColor: t.colorScheme.surfaceContainerLow,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: showContinueButton
                        ? FilledButton.icon(
                            onPressed: () => _openContinueReader(context, ref),
                            icon: const Icon(
                              Icons.auto_stories_outlined,
                              size: 18,
                            ),
                            label: Text(continueLabel),
                          )
                        : OutlinedButton(
                            onPressed: () => context.push(
                              RouteNames.novelDetail(bookmark.novelId),
                            ),
                            child: const Text('Xem truyện'),
                          ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Tùy chọn truyện',
                    onSelected: (_) => onRemove(),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Bỏ khỏi tủ sách'),
                      ),
                    ],
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
