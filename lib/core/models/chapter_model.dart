import 'package:equatable/equatable.dart';

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  return _toInt(value);
}

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
      number: _toInt(json['number']),
        title: json['title'] as String,
        content: json['content'] as String,
      views: _toInt(json['views']),
      volumeNumber: _toNullableInt(json['volumeNumber']),
        volumeTitle: json['volumeTitle'] as String?,
      volumeChapterNumber: _toNullableInt(json['volumeChapterNumber']),
        prevChapterId: json['prevChapterId'] as String?,
      prevChapterNumber: _toNullableInt(json['prevChapterNumber']),
        nextChapterId: json['nextChapterId'] as String?,
      nextChapterNumber: _toNullableInt(json['nextChapterNumber']),
      createdAt: _toDateTime(json['createdAt']),
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
      number: _toInt(json['number']),
        title: json['title'] as String,
      volumeNumber: _toNullableInt(json['volumeNumber']),
        volumeTitle: json['volumeTitle'] as String?,
      volumeChapterNumber: _toNullableInt(json['volumeChapterNumber']),
      createdAt: _toDateTime(json['createdAt']),
      );

  @override
  List<Object?> get props => [id, number];
}
