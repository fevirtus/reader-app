import 'package:equatable/equatable.dart';

import 'novel_model.dart';

enum BookmarkType {
  reading('reading'),
  bookmarked('bookmarked');

  const BookmarkType(this.value);
  final String value;

  static BookmarkType fromString(String? str) {
    return values.firstWhere(
      (e) => e.value == str,
      orElse: () => BookmarkType.bookmarked,
    );
  }
}

enum ShelfStatus {
  reading('reading'),
  completed('completed'),
  saved('saved');

  const ShelfStatus(this.value);
  final String value;

  static ShelfStatus fromString(String? str) {
    return values.firstWhere(
      (e) => e.value == str,
      orElse: () => ShelfStatus.saved,
    );
  }
}

class BookmarkModel extends Equatable {
  const BookmarkModel({
    required this.id,
    required this.novelId,
    this.type = BookmarkType.bookmarked,
    this.shelfStatus = ShelfStatus.saved,
    this.lastChapterId,
    this.lastChapterNumber,
    this.readChapters = const [],
    this.novel,
  });

  final String id;
  final String novelId;
  final BookmarkType type;
  final ShelfStatus shelfStatus;
  final String? lastChapterId;
  final int? lastChapterNumber;
  final List<int> readChapters;
  final NovelModel? novel;

  static ShelfStatus resolveShelfStatus({
    String? explicitShelfStatus,
    int? lastChapterNumber,
    List<int> readChapters = const [],
    int? totalChapters,
  }) {
    if (explicitShelfStatus == 'reading' ||
        explicitShelfStatus == 'completed' ||
        explicitShelfStatus == 'saved') {
      return ShelfStatus.fromString(explicitShelfStatus);
    }

    final hasProgress = lastChapterNumber != null || readChapters.isNotEmpty;
    final total = totalChapters ?? 0;
    if (hasProgress &&
        total > 0 &&
        lastChapterNumber != null &&
        lastChapterNumber >= total) {
      return ShelfStatus.completed;
    }
    if (hasProgress) {
      return ShelfStatus.reading;
    }
    return ShelfStatus.saved;
  }

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    final lastChapterNumber = (json['lastChapterNumber'] as num?)?.toInt();
    final readChapters = (json['readChapters'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const <int>[];
    final novel = json['novel'] != null
        ? NovelModel.fromJson(json['novel'] as Map<String, dynamic>)
        : null;
    final shelfStatus = resolveShelfStatus(
      explicitShelfStatus: json['shelfStatus'] as String?,
      lastChapterNumber: lastChapterNumber,
      readChapters: readChapters,
      totalChapters: novel?.totalChapters,
    );

    return BookmarkModel(
      id: json['id'] as String,
      novelId: json['novelId'] as String,
      lastChapterId: json['lastChapterId'] as String?,
      lastChapterNumber: lastChapterNumber,
      readChapters: readChapters,
      shelfStatus: shelfStatus,
      type: () {
        final explicitType = BookmarkType.fromString(json['type'] as String?);
        if ((json['type'] as String?) != null) {
          return explicitType;
        }

        return shelfStatus == ShelfStatus.saved
            ? BookmarkType.bookmarked
            : BookmarkType.reading;
      }(),
      novel: novel,
    );
  }

  BookmarkModel copyWith({
    String? lastChapterId,
    int? lastChapterNumber,
    List<int>? readChapters,
    ShelfStatus? shelfStatus,
    BookmarkType? type,
    NovelModel? novel,
  }) {
    final mergedReadChapters = readChapters ?? this.readChapters;
    final mergedLastChapterNumber = lastChapterNumber ?? this.lastChapterNumber;
    final mergedNovel = novel ?? this.novel;
    final mergedShelfStatus = shelfStatus ??
        resolveShelfStatus(
          lastChapterNumber: mergedLastChapterNumber,
          readChapters: mergedReadChapters,
          totalChapters: mergedNovel?.totalChapters,
        );

    return BookmarkModel(
      id: id,
      novelId: novelId,
      lastChapterId: lastChapterId ?? this.lastChapterId,
      lastChapterNumber: mergedLastChapterNumber,
      readChapters: mergedReadChapters,
      shelfStatus: mergedShelfStatus,
      type: type ??
          (mergedShelfStatus == ShelfStatus.saved
              ? BookmarkType.bookmarked
              : BookmarkType.reading),
      novel: mergedNovel,
    );
  }

  @override
  List<Object?> get props => [id, novelId, type, shelfStatus];
}
