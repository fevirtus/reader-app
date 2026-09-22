import '../../../shared/widgets/book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/repositories/downloads_repository.dart';
import '../../../core/storage/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/downloads_provider.dart';

/// Tab "Đã tải xuống" trong Tủ sách — liệt kê các truyện đã/đang tải để đọc
/// ngoại tuyến, cho phép huỷ khi đang tải và xoá khi đã xong.
class DownloadsTab extends ConsumerWidget {
  const DownloadsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsListProvider);
    final downloads = downloadsAsync.valueOrNull ?? const [];

    if (downloads.isEmpty) {
      return const EmptyState(
        icon: Icons.download_for_offline_outlined,
        title: 'Chưa tải truyện nào để đọc ngoại tuyến',
        subtitle: 'Vào trang chi tiết truyện và bấm "Tải xuống"',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      itemCount: downloads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _DownloadTile(entry: downloads[index]),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({required this.entry});
  final DownloadWithNovel entry;

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final download = entry.download;
    final novel = entry.novel;
    final actions = ref.read(downloadActionsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push(RouteNames.novelDetail(download.novelId)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(url: novel?.coverUrl, width: 72, height: 104),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel?.title ?? download.novelId,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusLine(download: download, formatBytes: _formatBytes),
                  if (download.status == 'downloading' &&
                      download.totalChapters > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            download.downloadedChapters /
                            download.totalChapters,
                        minHeight: 6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (download.status != 'downloading')
                        TextButton.icon(
                          onPressed: () => actions.start(download.novelId),
                          icon: const Icon(Icons.sync_rounded, size: 18),
                          label: const Text('Cập nhật'),
                        ),
                      if (download.status == 'downloading')
                        TextButton.icon(
                          onPressed: () => actions.cancel(download.novelId),
                          icon: const Icon(
                            Icons.pause_circle_outline,
                            size: 18,
                          ),
                          label: const Text('Tạm dừng'),
                        )
                      else if (download.status == 'done')
                        TextButton.icon(
                          onPressed: () => context.push(
                            RouteNames.novelDetail(download.novelId),
                          ),
                          icon: const Icon(
                            Icons.auto_stories_outlined,
                            size: 18,
                          ),
                          label: const Text('Mở truyện'),
                        )
                      else if (download.status == 'failed' ||
                          download.status == 'paused')
                        TextButton.icon(
                          onPressed: () => actions.start(download.novelId),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Tải lại'),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => actions.delete(download.novelId),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        tooltip: 'Xoá bản tải',
                      ),
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

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.download, required this.formatBytes});
  final Download download;
  final String Function(int) formatBytes;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
    switch (download.status) {
      case 'downloading':
        return Text(
          'Đang tải ${download.downloadedChapters}/${download.totalChapters} chương',
          style: style,
        );
      case 'done':
        return Text(
          '${download.totalChapters} chương · ${formatBytes(download.bytesSize)}',
          style: style?.copyWith(color: success, fontWeight: FontWeight.w600),
        );
      case 'paused':
        return Text(
          'Đã tạm dừng ở ${download.downloadedChapters}/${download.totalChapters} chương',
          style: style,
        );
      case 'failed':
        return Text(
          download.errorMessage ?? 'Tải lỗi',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style?.copyWith(color: Theme.of(context).colorScheme.error),
        );
      default:
        return Text('Đang chờ tải...', style: style);
    }
  }
}
