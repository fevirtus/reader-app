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

class BookmarkModel extends Equatable {
  const BookmarkModel({
    required this.id,
    required this.novelId,
    this.type = BookmarkType.bookmarked,
    this.lastChapterId,
    this.lastChapterNumber,
    this.readChapters = const [],
    this.novel,
  });

  final String id;
  final String novelId;
  final BookmarkType type;
  final String? lastChapterId;
  final int? lastChapterNumber;
  final List<int> readChapters;
  final NovelModel? novel;

  factory BookmarkModel.fromJson(Map<String, dynamic> json) => BookmarkModel(
        id: json['id'] as String,
        novelId: json['novelId'] as String,
        lastChapterId: json['lastChapterId'] as String?,
        lastChapterNumber: json['lastChapterNumber'] as int?,
        readChapters: (json['readChapters'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [],
        type: () {
          final explicitType = BookmarkType.fromString(json['type'] as String?);
          if ((json['type'] as String?) != null) {
            return explicitType;
          }

          // Backward-compatible inference when API does not return `type`.
          final inferredLastChapter = json['lastChapterNumber'] as int?;
          final inferredReadChapters = (json['readChapters'] as List<dynamic>?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              const <int>[];
          return (inferredLastChapter != null || inferredReadChapters.isNotEmpty)
              ? BookmarkType.reading
              : BookmarkType.bookmarked;
        }(),
        novel: json['novel'] != null
            ? NovelModel.fromJson(json['novel'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, novelId, type];
}
