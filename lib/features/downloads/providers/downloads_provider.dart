import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/download/download_manager.dart';
import '../../../core/repositories/downloads_repository.dart';
import '../../../core/storage/database/app_database.dart';

/// Toàn bộ danh sách truyện đã/đang tải, kèm thông tin truyện — dùng cho màn
/// hình "Đã tải xuống".
final downloadsListProvider = StreamProvider<List<DownloadWithNovel>>((ref) {
  return ref.watch(downloadsRepositoryProvider).watchAllWithNovels();
});

/// Trạng thái tải của một truyện cụ thể — dùng cho nút tải ở màn Chi tiết truyện.
final downloadForNovelProvider = StreamProvider.family<Download?, String>((ref, novelId) {
  return ref.watch(downloadsRepositoryProvider).watchForNovel(novelId);
});

class DownloadActions {
  DownloadActions(this._ref);
  final Ref _ref;

  Future<void> start(String novelId) => _ref.read(downloadManagerProvider).startDownload(novelId);

  void cancel(String novelId) => _ref.read(downloadManagerProvider).cancelDownload(novelId);

  Future<void> delete(String novelId) => _ref.read(downloadManagerProvider).deleteDownload(novelId);
}

final downloadActionsProvider = Provider<DownloadActions>((ref) => DownloadActions(ref));
