import '../../audiobook/audio_book_screen.dart';
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
class DownloadsTab extends StatelessWidget {
  const DownloadsTab({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.headphones_outlined),
        title: const Text('Audio book offline'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const AudioBookDownloadsScreen(),
          ),
        ),
      ),
      const Expanded(child: _TextDownloadsTab()),
    ],
  );
}

class _TextDownloadsTab extends ConsumerWidget {
  const _TextDownloadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsListProvider);
    if (!downloadsAsync.hasValue) {
      if (downloadsAsync.hasError) {
        return EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Chưa đọc được danh sách tải xuống',
          actionLabel: 'Thử lại',
          onAction: () => ref.invalidate(downloadsListProvider),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    final downloads = downloadsAsync.value!;

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

    return InkWell(
      borderRadius: BorderRadius.circular(18),
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
                            (download.downloadedChapters /
                                    download.totalChapters)
                                .clamp(0.0, 1.0),
                        minHeight: 6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (download.status == 'done' || download.bytesSize > 0)
                        FilledButton.tonalIcon(
                          onPressed: () => context.push(
                            RouteNames.novelDetail(download.novelId),
                          ),
                          icon: const Icon(
                            Icons.auto_stories_outlined,
                            size: 18,
                          ),
                          label: const Text('Mở truyện'),
                        ),
                      if (download.status == 'downloading')
                        TextButton.icon(
                          onPressed: () => actions.cancel(download.novelId),
                          icon: const Icon(Icons.pause_rounded, size: 18),
                          label: const Text('Tạm dừng'),
                        )
                      else if (download.status != 'done')
                        TextButton.icon(
                          onPressed: () => actions.start(download.novelId),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(
                            download.status == 'paused'
                                ? 'Tiếp tục tải'
                                : 'Thử lại',
                          ),
                        ),
                      PopupMenuButton<String>(
                        tooltip: 'Tuỳ chọn bản tải',
                        icon: const Icon(Icons.more_horiz_rounded),
                        itemBuilder: (_) => [
                          if (download.status != 'downloading')
                            const PopupMenuItem(
                              value: 'update',
                              child: Text('Cập nhật bản tải'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Xoá bản tải'),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'update') {
                            await actions.start(download.novelId);
                            return;
                          }
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xoá bản tải xuống?'),
                              content: const Text(
                                'Bạn sẽ cần tải lại để đọc ngoại tuyến. Tiến độ đọc và truyện trong tủ sách vẫn được giữ.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Giữ lại'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Xoá bản tải'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await actions.delete(download.novelId);
                          }
                        },
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
          download.bytesSize > 0
              ? 'Chưa cập nhật được. Bản đã tải vẫn đọc được.'
              : 'Tải chưa hoàn tất. Kiểm tra kết nối rồi thử lại.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style?.copyWith(color: Theme.of(context).colorScheme.error),
        );
      default:
        return Text('Đang chờ tải...', style: style);
    }
  }
}
