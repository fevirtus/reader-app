import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/bookmark_model.dart';
import '../../models/chapter_model.dart';
import '../../models/novel_model.dart';
import 'app_database.dart';

/// Chuyển đổi giữa các model dùng cho API (`NovelModel`, `GenreModel`, `BookmarkModel`)
/// và các bản ghi Drift tương ứng, để repository không phải rải logic (de)serialize khắp nơi.

extension NovelModelMapping on NovelModel {
  NovelsCompanion toCompanion() => NovelsCompanion.insert(
    id: id,
    title: title,
    slug: slug,
    authorName: authorName,
    status: status,
    totalChapters: Value(totalChapters),
    updatedAt: Value(updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
    originalTitle: Value(originalTitle),
    description: Value(description),
    coverUrl: Value(coverUrl),
    coverColor: Value(coverColor),
    views: Value(views),
    rating: Value(rating),
    ratingCount: Value(ratingCount),
    userRating: Value(userRating),
    bookmarkCount: Value(bookmarkCount),
    seriesId: Value(seriesId),
    genresJson: Value(
      genres.isEmpty
          ? null
          : jsonEncode(genres.map((g) => g.toJson()).toList()),
    ),
    seriesJson: Value(series == null ? null : jsonEncode(series!.toJson())),
    latestChapterJson: Value(
      latestChapter == null ? null : jsonEncode(latestChapter!.toJson()),
    ),
  );
}

extension NovelRowMapping on Novel {
  NovelModel toModel() => NovelModel(
    id: id,
    title: title,
    slug: slug,
    authorName: authorName,
    status: status,
    totalChapters: totalChapters,
    updatedAt: updatedAt,
    originalTitle: originalTitle,
    description: description,
    coverUrl: coverUrl,
    coverColor: coverColor,
    views: views,
    rating: rating,
    ratingCount: ratingCount,
    // Ratings belong to an account; shared novel cache is not an authority for them.
    userRating: null,
    bookmarkCount: bookmarkCount,
    seriesId: seriesId,
    genres: genresJson == null
        ? const []
        : (jsonDecode(genresJson!) as List)
              .map((g) => GenreModel.fromJson(g as Map<String, dynamic>))
              .toList(),
    series: seriesJson == null
        ? null
        : SeriesModel.fromJson(jsonDecode(seriesJson!) as Map<String, dynamic>),
    latestChapter: latestChapterJson == null
        ? null
        : LatestChapterInfo.fromJson(
            jsonDecode(latestChapterJson!) as Map<String, dynamic>,
          ),
  );
}

extension GenreModelMapping on GenreModel {
  GenresCompanion toCompanion() => GenresCompanion.insert(
    id: id,
    name: name,
    slug: slug,
    description: Value(description),
    icon: Value(icon),
    novelCount: Value(novelCount),
  );
}

extension GenreRowMapping on Genre {
  GenreModel toModel() => GenreModel(
    id: id,
    name: name,
    slug: slug,
    description: description,
    icon: icon,
    novelCount: novelCount,
  );
}

extension BookmarkModelMapping on BookmarkModel {
  BookmarksCompanion toCompanion() => BookmarksCompanion.insert(
    id: id,
    novelId: novelId,
    type: type.value,
    shelfStatus: shelfStatus.value,
    lastChapterId: Value(lastChapterId),
    lastChapterNumber: Value(lastChapterNumber),
    readChaptersJson: Value(jsonEncode(readChapters)),
    markedAsRead: Value(markedAsRead),
  );
}

extension ChapterModelMapping on ChapterModel {
  ChapterContentsCompanion toCompanion({required bool isDownloaded}) =>
      ChapterContentsCompanion.insert(
        chapterId: id,
        novelId: novelId,
        number: number,
        title: title,
        content: content,
        prevChapterId: Value(prevChapterId),
        prevChapterNumber: Value(prevChapterNumber),
        nextChapterId: Value(nextChapterId),
        nextChapterNumber: Value(nextChapterNumber),
        volumeTitle: Value(volumeTitle),
        isDownloaded: Value(isDownloaded),
      );
}

extension ChapterContentRowMapping on ChapterContent {
  ChapterModel toModel() => ChapterModel(
    id: chapterId,
    novelId: novelId,
    number: number,
    title: title,
    content: content,
    prevChapterId: prevChapterId,
    prevChapterNumber: prevChapterNumber,
    nextChapterId: nextChapterId,
    nextChapterNumber: nextChapterNumber,
    volumeTitle: volumeTitle,
    createdAt: cachedAt,
  );
}

extension BookmarkRowMapping on Bookmark {
  BookmarkModel toModel({NovelModel? novel}) => BookmarkModel(
    id: id,
    novelId: novelId,
    type: BookmarkType.fromString(type),
    shelfStatus: ShelfStatus.fromString(shelfStatus),
    lastChapterId: lastChapterId,
    lastChapterNumber: lastChapterNumber,
    readChapters: (jsonDecode(readChaptersJson) as List)
        .map((e) => (e as num).toInt())
        .toList(),
    markedAsRead: markedAsRead,
    novel: novel,
  );
}
