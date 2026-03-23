import 'package:equatable/equatable.dart';

class ChapterModel extends Equatable {
  const ChapterModel({
    required this.id,
    required this.novelId,
    required this.number,
    required this.title,
    required this.content,
    this.views = 0,
    this.volumeNumber,
    this.volumeTitle,
    this.volumeChapterNumber,
    this.prevChapterId,
    this.prevChapterNumber,
    this.nextChapterId,
    this.nextChapterNumber,
    required this.createdAt,
  });

  final String id;
  final String novelId;
  final int number;
  final String title;
  final String content;
  final int views;
  final int? volumeNumber;
  final String? volumeTitle;
  final int? volumeChapterNumber;
  final String? prevChapterId;
  final int? prevChapterNumber;
  final String? nextChapterId;
  final int? nextChapterNumber;
  final DateTime createdAt;

  factory ChapterModel.fromJson(Map<String, dynamic> json) => ChapterModel(
        id: json['id'] as String,
        novelId: json['novelId'] as String,
        number: (json['number'] as num).toInt(),
        title: json['title'] as String,
        content: json['content'] as String,
        views: (json['views'] as num?)?.toInt() ?? 0,
        volumeNumber: json['volumeNumber'] as int?,
        volumeTitle: json['volumeTitle'] as String?,
        volumeChapterNumber: json['volumeChapterNumber'] as int?,
        prevChapterId: json['prevChapterId'] as String?,
        prevChapterNumber: json['prevChapterNumber'] as int?,
        nextChapterId: json['nextChapterId'] as String?,
        nextChapterNumber: json['nextChapterNumber'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [id, number];
}

class ChapterListItem extends Equatable {
  const ChapterListItem({
    required this.id,
    required this.number,
    required this.title,
    this.volumeNumber,
    this.volumeTitle,
    this.volumeChapterNumber,
    required this.createdAt,
  });

  final String id;
  final int number;
  final String title;
  final int? volumeNumber;
  final String? volumeTitle;
  final int? volumeChapterNumber;
  final DateTime createdAt;

  factory ChapterListItem.fromJson(Map<String, dynamic> json) => ChapterListItem(
        id: json['id'] as String,
        number: (json['number'] as num).toInt(),
        title: json['title'] as String,
        volumeNumber: json['volumeNumber'] as int?,
        volumeTitle: json['volumeTitle'] as String?,
        volumeChapterNumber: json['volumeChapterNumber'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [id, number];
}
