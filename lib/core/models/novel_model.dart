import 'package:equatable/equatable.dart';

class NovelModel extends Equatable {
  const NovelModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.authorName,
    required this.status,
    required this.totalChapters,
    this.originalTitle,
    this.description,
    this.coverUrl,
    this.coverColor,
    this.views = 0,
    this.rating = 0,
    this.ratingCount = 0,
    this.bookmarkCount = 0,
    this.genres = const [],
    this.seriesId,
    this.series,
    this.latestChapter,
  });

  final String id;
  final String title;
  final String slug;
  final String authorName;
  final String status;
  final int totalChapters;
  final String? originalTitle;
  final String? description;
  final String? coverUrl;
  final String? coverColor;
  final int views;
  final double rating;
  final int ratingCount;
  final int bookmarkCount;
  final List<GenreModel> genres;
  final String? seriesId;
  final SeriesModel? series;
  final LatestChapterInfo? latestChapter;

  static String _stringValue(dynamic value, {String fallback = ''}) {
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }

  static int _intValue(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return fallback;
  }

  factory NovelModel.fromJson(Map<String, dynamic> json) => NovelModel(
        id: _stringValue(json['id']),
        title: _stringValue(json['title'], fallback: 'Không rõ tiêu đề'),
        slug: _stringValue(json['slug']),
        authorName: _stringValue(json['authorName'], fallback: 'Chưa rõ tác giả'),
        status: _stringValue(json['status'], fallback: 'Đang ra'),
        totalChapters: _intValue(json['totalChapters']),
        originalTitle: json['originalTitle'] as String?,
        description: json['description'] as String?,
        coverUrl: json['coverUrl'] as String?,
        coverColor: json['coverColor'] as String?,
        views: (json['views'] as num?)?.toInt() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        bookmarkCount: (json['bookmarkCount'] as num?)?.toInt() ?? 0,
        genres: (json['genres'] as List<dynamic>?)
                ?.map((g) => GenreModel.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
        seriesId: json['seriesId'] as String?,
        series: json['series'] != null
            ? SeriesModel.fromJson(json['series'] as Map<String, dynamic>)
            : null,
        latestChapter: json['latestChapter'] != null
            ? LatestChapterInfo.fromJson(
                json['latestChapter'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, slug];
}

class GenreModel extends Equatable {
  const GenreModel({required this.id, required this.name, required this.slug, this.description, this.icon, this.novelCount = 0});
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final int novelCount;

  factory GenreModel.fromJson(Map<String, dynamic> json) => GenreModel(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        novelCount: (json['novelCount'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, slug];
}

class SeriesModel extends Equatable {
  const SeriesModel({required this.id, required this.name, required this.slug, this.novels = const []});
  final String id;
  final String name;
  final String slug;
  final List<NovelModel> novels;

  factory SeriesModel.fromJson(Map<String, dynamic> json) => SeriesModel(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        novels: (json['novels'] as List<dynamic>?)
                ?.map((n) => NovelModel.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props => [id, slug];
}

class LatestChapterInfo extends Equatable {
  const LatestChapterInfo({required this.number, required this.title, required this.createdAt});
  final int number;
  final String title;
  final DateTime createdAt;

  factory LatestChapterInfo.fromJson(Map<String, dynamic> json) => LatestChapterInfo(
        number: (json['number'] as num).toInt(),
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [number];
}
