import 'package:equatable/equatable.dart';

import 'novel_model.dart';

class BookmarkModel extends Equatable {
  const BookmarkModel({
    required this.id,
    required this.novelId,
    this.lastChapterId,
    this.lastChapterNumber,
    this.readChapters = const [],
    this.novel,
  });

  final String id;
  final String novelId;
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
        novel: json['novel'] != null
            ? NovelModel.fromJson(json['novel'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, novelId];
}
