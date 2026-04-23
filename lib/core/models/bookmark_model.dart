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
        type: BookmarkType.fromString(json['type'] as String?),
        lastChapterId: json['lastChapterId'] as String?,
        lastChapterNumber: json['lastChapterNumber'] as int?,
        readChapters: (json['readChapters'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [],
        novel: json['novel'] != null
            ? NovelModel.fromJson(json['novel'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, novelId, type];
}
