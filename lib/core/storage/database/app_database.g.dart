// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NovelsTable extends Novels with TableInfo<$NovelsTable, Novel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NovelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorNameMeta =
      const VerificationMeta('authorName');
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
      'author_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalChaptersMeta =
      const VerificationMeta('totalChapters');
  @override
  late final GeneratedColumn<int> totalChapters = GeneratedColumn<int>(
      'total_chapters', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _originalTitleMeta =
      const VerificationMeta('originalTitle');
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
      'original_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverColorMeta =
      const VerificationMeta('coverColor');
  @override
  late final GeneratedColumn<String> coverColor = GeneratedColumn<String>(
      'cover_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _viewsMeta = const VerificationMeta('views');
  @override
  late final GeneratedColumn<int> views = GeneratedColumn<int>(
      'views', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _ratingCountMeta =
      const VerificationMeta('ratingCount');
  @override
  late final GeneratedColumn<int> ratingCount = GeneratedColumn<int>(
      'rating_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _userRatingMeta =
      const VerificationMeta('userRating');
  @override
  late final GeneratedColumn<double> userRating = GeneratedColumn<double>(
      'user_rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bookmarkCountMeta =
      const VerificationMeta('bookmarkCount');
  @override
  late final GeneratedColumn<int> bookmarkCount = GeneratedColumn<int>(
      'bookmark_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _seriesIdMeta =
      const VerificationMeta('seriesId');
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
      'series_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genresJsonMeta =
      const VerificationMeta('genresJson');
  @override
  late final GeneratedColumn<String> genresJson = GeneratedColumn<String>(
      'genres_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _seriesJsonMeta =
      const VerificationMeta('seriesJson');
  @override
  late final GeneratedColumn<String> seriesJson = GeneratedColumn<String>(
      'series_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latestChapterJsonMeta =
      const VerificationMeta('latestChapterJson');
  @override
  late final GeneratedColumn<String> latestChapterJson =
      GeneratedColumn<String>('latest_chapter_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        slug,
        authorName,
        status,
        totalChapters,
        originalTitle,
        description,
        coverUrl,
        coverColor,
        views,
        rating,
        ratingCount,
        userRating,
        bookmarkCount,
        seriesId,
        genresJson,
        seriesJson,
        latestChapterJson,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'novels';
  @override
  VerificationContext validateIntegrity(Insertable<Novel> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('author_name')) {
      context.handle(
          _authorNameMeta,
          authorName.isAcceptableOrUnknown(
              data['author_name']!, _authorNameMeta));
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_chapters')) {
      context.handle(
          _totalChaptersMeta,
          totalChapters.isAcceptableOrUnknown(
              data['total_chapters']!, _totalChaptersMeta));
    }
    if (data.containsKey('original_title')) {
      context.handle(
          _originalTitleMeta,
          originalTitle.isAcceptableOrUnknown(
              data['original_title']!, _originalTitleMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('cover_color')) {
      context.handle(
          _coverColorMeta,
          coverColor.isAcceptableOrUnknown(
              data['cover_color']!, _coverColorMeta));
    }
    if (data.containsKey('views')) {
      context.handle(
          _viewsMeta, views.isAcceptableOrUnknown(data['views']!, _viewsMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('rating_count')) {
      context.handle(
          _ratingCountMeta,
          ratingCount.isAcceptableOrUnknown(
              data['rating_count']!, _ratingCountMeta));
    }
    if (data.containsKey('user_rating')) {
      context.handle(
          _userRatingMeta,
          userRating.isAcceptableOrUnknown(
              data['user_rating']!, _userRatingMeta));
    }
    if (data.containsKey('bookmark_count')) {
      context.handle(
          _bookmarkCountMeta,
          bookmarkCount.isAcceptableOrUnknown(
              data['bookmark_count']!, _bookmarkCountMeta));
    }
    if (data.containsKey('series_id')) {
      context.handle(_seriesIdMeta,
          seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta));
    }
    if (data.containsKey('genres_json')) {
      context.handle(
          _genresJsonMeta,
          genresJson.isAcceptableOrUnknown(
              data['genres_json']!, _genresJsonMeta));
    }
    if (data.containsKey('series_json')) {
      context.handle(
          _seriesJsonMeta,
          seriesJson.isAcceptableOrUnknown(
              data['series_json']!, _seriesJsonMeta));
    }
    if (data.containsKey('latest_chapter_json')) {
      context.handle(
          _latestChapterJsonMeta,
          latestChapterJson.isAcceptableOrUnknown(
              data['latest_chapter_json']!, _latestChapterJsonMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Novel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Novel(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
      authorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author_name'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      totalChapters: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_chapters'])!,
      originalTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_title']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      coverColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_color']),
      views: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}views'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating'])!,
      ratingCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating_count'])!,
      userRating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}user_rating']),
      bookmarkCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bookmark_count'])!,
      seriesId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_id']),
      genresJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genres_json']),
      seriesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_json']),
      latestChapterJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}latest_chapter_json']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $NovelsTable createAlias(String alias) {
    return $NovelsTable(attachedDatabase, alias);
  }
}

class Novel extends DataClass implements Insertable<Novel> {
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
  final double? userRating;
  final int bookmarkCount;
  final String? seriesId;
  final String? genresJson;
  final String? seriesJson;
  final String? latestChapterJson;
  final DateTime updatedAt;
  const Novel(
      {required this.id,
      required this.title,
      required this.slug,
      required this.authorName,
      required this.status,
      required this.totalChapters,
      this.originalTitle,
      this.description,
      this.coverUrl,
      this.coverColor,
      required this.views,
      required this.rating,
      required this.ratingCount,
      this.userRating,
      required this.bookmarkCount,
      this.seriesId,
      this.genresJson,
      this.seriesJson,
      this.latestChapterJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['slug'] = Variable<String>(slug);
    map['author_name'] = Variable<String>(authorName);
    map['status'] = Variable<String>(status);
    map['total_chapters'] = Variable<int>(totalChapters);
    if (!nullToAbsent || originalTitle != null) {
      map['original_title'] = Variable<String>(originalTitle);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || coverColor != null) {
      map['cover_color'] = Variable<String>(coverColor);
    }
    map['views'] = Variable<int>(views);
    map['rating'] = Variable<double>(rating);
    map['rating_count'] = Variable<int>(ratingCount);
    if (!nullToAbsent || userRating != null) {
      map['user_rating'] = Variable<double>(userRating);
    }
    map['bookmark_count'] = Variable<int>(bookmarkCount);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || genresJson != null) {
      map['genres_json'] = Variable<String>(genresJson);
    }
    if (!nullToAbsent || seriesJson != null) {
      map['series_json'] = Variable<String>(seriesJson);
    }
    if (!nullToAbsent || latestChapterJson != null) {
      map['latest_chapter_json'] = Variable<String>(latestChapterJson);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NovelsCompanion toCompanion(bool nullToAbsent) {
    return NovelsCompanion(
      id: Value(id),
      title: Value(title),
      slug: Value(slug),
      authorName: Value(authorName),
      status: Value(status),
      totalChapters: Value(totalChapters),
      originalTitle: originalTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTitle),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      coverColor: coverColor == null && nullToAbsent
          ? const Value.absent()
          : Value(coverColor),
      views: Value(views),
      rating: Value(rating),
      ratingCount: Value(ratingCount),
      userRating: userRating == null && nullToAbsent
          ? const Value.absent()
          : Value(userRating),
      bookmarkCount: Value(bookmarkCount),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      genresJson: genresJson == null && nullToAbsent
          ? const Value.absent()
          : Value(genresJson),
      seriesJson: seriesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesJson),
      latestChapterJson: latestChapterJson == null && nullToAbsent
          ? const Value.absent()
          : Value(latestChapterJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory Novel.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Novel(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      slug: serializer.fromJson<String>(json['slug']),
      authorName: serializer.fromJson<String>(json['authorName']),
      status: serializer.fromJson<String>(json['status']),
      totalChapters: serializer.fromJson<int>(json['totalChapters']),
      originalTitle: serializer.fromJson<String?>(json['originalTitle']),
      description: serializer.fromJson<String?>(json['description']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      coverColor: serializer.fromJson<String?>(json['coverColor']),
      views: serializer.fromJson<int>(json['views']),
      rating: serializer.fromJson<double>(json['rating']),
      ratingCount: serializer.fromJson<int>(json['ratingCount']),
      userRating: serializer.fromJson<double?>(json['userRating']),
      bookmarkCount: serializer.fromJson<int>(json['bookmarkCount']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      genresJson: serializer.fromJson<String?>(json['genresJson']),
      seriesJson: serializer.fromJson<String?>(json['seriesJson']),
      latestChapterJson:
          serializer.fromJson<String?>(json['latestChapterJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'slug': serializer.toJson<String>(slug),
      'authorName': serializer.toJson<String>(authorName),
      'status': serializer.toJson<String>(status),
      'totalChapters': serializer.toJson<int>(totalChapters),
      'originalTitle': serializer.toJson<String?>(originalTitle),
      'description': serializer.toJson<String?>(description),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'coverColor': serializer.toJson<String?>(coverColor),
      'views': serializer.toJson<int>(views),
      'rating': serializer.toJson<double>(rating),
      'ratingCount': serializer.toJson<int>(ratingCount),
      'userRating': serializer.toJson<double?>(userRating),
      'bookmarkCount': serializer.toJson<int>(bookmarkCount),
      'seriesId': serializer.toJson<String?>(seriesId),
      'genresJson': serializer.toJson<String?>(genresJson),
      'seriesJson': serializer.toJson<String?>(seriesJson),
      'latestChapterJson': serializer.toJson<String?>(latestChapterJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Novel copyWith(
          {String? id,
          String? title,
          String? slug,
          String? authorName,
          String? status,
          int? totalChapters,
          Value<String?> originalTitle = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> coverUrl = const Value.absent(),
          Value<String?> coverColor = const Value.absent(),
          int? views,
          double? rating,
          int? ratingCount,
          Value<double?> userRating = const Value.absent(),
          int? bookmarkCount,
          Value<String?> seriesId = const Value.absent(),
          Value<String?> genresJson = const Value.absent(),
          Value<String?> seriesJson = const Value.absent(),
          Value<String?> latestChapterJson = const Value.absent(),
          DateTime? updatedAt}) =>
      Novel(
        id: id ?? this.id,
        title: title ?? this.title,
        slug: slug ?? this.slug,
        authorName: authorName ?? this.authorName,
        status: status ?? this.status,
        totalChapters: totalChapters ?? this.totalChapters,
        originalTitle:
            originalTitle.present ? originalTitle.value : this.originalTitle,
        description: description.present ? description.value : this.description,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        coverColor: coverColor.present ? coverColor.value : this.coverColor,
        views: views ?? this.views,
        rating: rating ?? this.rating,
        ratingCount: ratingCount ?? this.ratingCount,
        userRating: userRating.present ? userRating.value : this.userRating,
        bookmarkCount: bookmarkCount ?? this.bookmarkCount,
        seriesId: seriesId.present ? seriesId.value : this.seriesId,
        genresJson: genresJson.present ? genresJson.value : this.genresJson,
        seriesJson: seriesJson.present ? seriesJson.value : this.seriesJson,
        latestChapterJson: latestChapterJson.present
            ? latestChapterJson.value
            : this.latestChapterJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Novel copyWithCompanion(NovelsCompanion data) {
    return Novel(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      slug: data.slug.present ? data.slug.value : this.slug,
      authorName:
          data.authorName.present ? data.authorName.value : this.authorName,
      status: data.status.present ? data.status.value : this.status,
      totalChapters: data.totalChapters.present
          ? data.totalChapters.value
          : this.totalChapters,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      description:
          data.description.present ? data.description.value : this.description,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      coverColor:
          data.coverColor.present ? data.coverColor.value : this.coverColor,
      views: data.views.present ? data.views.value : this.views,
      rating: data.rating.present ? data.rating.value : this.rating,
      ratingCount:
          data.ratingCount.present ? data.ratingCount.value : this.ratingCount,
      userRating:
          data.userRating.present ? data.userRating.value : this.userRating,
      bookmarkCount: data.bookmarkCount.present
          ? data.bookmarkCount.value
          : this.bookmarkCount,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      genresJson:
          data.genresJson.present ? data.genresJson.value : this.genresJson,
      seriesJson:
          data.seriesJson.present ? data.seriesJson.value : this.seriesJson,
      latestChapterJson: data.latestChapterJson.present
          ? data.latestChapterJson.value
          : this.latestChapterJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Novel(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('slug: $slug, ')
          ..write('authorName: $authorName, ')
          ..write('status: $status, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverColor: $coverColor, ')
          ..write('views: $views, ')
          ..write('rating: $rating, ')
          ..write('ratingCount: $ratingCount, ')
          ..write('userRating: $userRating, ')
          ..write('bookmarkCount: $bookmarkCount, ')
          ..write('seriesId: $seriesId, ')
          ..write('genresJson: $genresJson, ')
          ..write('seriesJson: $seriesJson, ')
          ..write('latestChapterJson: $latestChapterJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      slug,
      authorName,
      status,
      totalChapters,
      originalTitle,
      description,
      coverUrl,
      coverColor,
      views,
      rating,
      ratingCount,
      userRating,
      bookmarkCount,
      seriesId,
      genresJson,
      seriesJson,
      latestChapterJson,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Novel &&
          other.id == this.id &&
          other.title == this.title &&
          other.slug == this.slug &&
          other.authorName == this.authorName &&
          other.status == this.status &&
          other.totalChapters == this.totalChapters &&
          other.originalTitle == this.originalTitle &&
          other.description == this.description &&
          other.coverUrl == this.coverUrl &&
          other.coverColor == this.coverColor &&
          other.views == this.views &&
          other.rating == this.rating &&
          other.ratingCount == this.ratingCount &&
          other.userRating == this.userRating &&
          other.bookmarkCount == this.bookmarkCount &&
          other.seriesId == this.seriesId &&
          other.genresJson == this.genresJson &&
          other.seriesJson == this.seriesJson &&
          other.latestChapterJson == this.latestChapterJson &&
          other.updatedAt == this.updatedAt);
}

class NovelsCompanion extends UpdateCompanion<Novel> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> slug;
  final Value<String> authorName;
  final Value<String> status;
  final Value<int> totalChapters;
  final Value<String?> originalTitle;
  final Value<String?> description;
  final Value<String?> coverUrl;
  final Value<String?> coverColor;
  final Value<int> views;
  final Value<double> rating;
  final Value<int> ratingCount;
  final Value<double?> userRating;
  final Value<int> bookmarkCount;
  final Value<String?> seriesId;
  final Value<String?> genresJson;
  final Value<String?> seriesJson;
  final Value<String?> latestChapterJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const NovelsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.slug = const Value.absent(),
    this.authorName = const Value.absent(),
    this.status = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.views = const Value.absent(),
    this.rating = const Value.absent(),
    this.ratingCount = const Value.absent(),
    this.userRating = const Value.absent(),
    this.bookmarkCount = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.genresJson = const Value.absent(),
    this.seriesJson = const Value.absent(),
    this.latestChapterJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NovelsCompanion.insert({
    required String id,
    required String title,
    required String slug,
    required String authorName,
    required String status,
    this.totalChapters = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.views = const Value.absent(),
    this.rating = const Value.absent(),
    this.ratingCount = const Value.absent(),
    this.userRating = const Value.absent(),
    this.bookmarkCount = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.genresJson = const Value.absent(),
    this.seriesJson = const Value.absent(),
    this.latestChapterJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        slug = Value(slug),
        authorName = Value(authorName),
        status = Value(status);
  static Insertable<Novel> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? slug,
    Expression<String>? authorName,
    Expression<String>? status,
    Expression<int>? totalChapters,
    Expression<String>? originalTitle,
    Expression<String>? description,
    Expression<String>? coverUrl,
    Expression<String>? coverColor,
    Expression<int>? views,
    Expression<double>? rating,
    Expression<int>? ratingCount,
    Expression<double>? userRating,
    Expression<int>? bookmarkCount,
    Expression<String>? seriesId,
    Expression<String>? genresJson,
    Expression<String>? seriesJson,
    Expression<String>? latestChapterJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (slug != null) 'slug': slug,
      if (authorName != null) 'author_name': authorName,
      if (status != null) 'status': status,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (originalTitle != null) 'original_title': originalTitle,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (coverColor != null) 'cover_color': coverColor,
      if (views != null) 'views': views,
      if (rating != null) 'rating': rating,
      if (ratingCount != null) 'rating_count': ratingCount,
      if (userRating != null) 'user_rating': userRating,
      if (bookmarkCount != null) 'bookmark_count': bookmarkCount,
      if (seriesId != null) 'series_id': seriesId,
      if (genresJson != null) 'genres_json': genresJson,
      if (seriesJson != null) 'series_json': seriesJson,
      if (latestChapterJson != null) 'latest_chapter_json': latestChapterJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NovelsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? slug,
      Value<String>? authorName,
      Value<String>? status,
      Value<int>? totalChapters,
      Value<String?>? originalTitle,
      Value<String?>? description,
      Value<String?>? coverUrl,
      Value<String?>? coverColor,
      Value<int>? views,
      Value<double>? rating,
      Value<int>? ratingCount,
      Value<double?>? userRating,
      Value<int>? bookmarkCount,
      Value<String?>? seriesId,
      Value<String?>? genresJson,
      Value<String?>? seriesJson,
      Value<String?>? latestChapterJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return NovelsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      totalChapters: totalChapters ?? this.totalChapters,
      originalTitle: originalTitle ?? this.originalTitle,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      coverColor: coverColor ?? this.coverColor,
      views: views ?? this.views,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      userRating: userRating ?? this.userRating,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      seriesId: seriesId ?? this.seriesId,
      genresJson: genresJson ?? this.genresJson,
      seriesJson: seriesJson ?? this.seriesJson,
      latestChapterJson: latestChapterJson ?? this.latestChapterJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalChapters.present) {
      map['total_chapters'] = Variable<int>(totalChapters.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (coverColor.present) {
      map['cover_color'] = Variable<String>(coverColor.value);
    }
    if (views.present) {
      map['views'] = Variable<int>(views.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (ratingCount.present) {
      map['rating_count'] = Variable<int>(ratingCount.value);
    }
    if (userRating.present) {
      map['user_rating'] = Variable<double>(userRating.value);
    }
    if (bookmarkCount.present) {
      map['bookmark_count'] = Variable<int>(bookmarkCount.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (genresJson.present) {
      map['genres_json'] = Variable<String>(genresJson.value);
    }
    if (seriesJson.present) {
      map['series_json'] = Variable<String>(seriesJson.value);
    }
    if (latestChapterJson.present) {
      map['latest_chapter_json'] = Variable<String>(latestChapterJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NovelsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('slug: $slug, ')
          ..write('authorName: $authorName, ')
          ..write('status: $status, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverColor: $coverColor, ')
          ..write('views: $views, ')
          ..write('rating: $rating, ')
          ..write('ratingCount: $ratingCount, ')
          ..write('userRating: $userRating, ')
          ..write('bookmarkCount: $bookmarkCount, ')
          ..write('seriesId: $seriesId, ')
          ..write('genresJson: $genresJson, ')
          ..write('seriesJson: $seriesJson, ')
          ..write('latestChapterJson: $latestChapterJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GenresTable extends Genres with TableInfo<$GenresTable, Genre> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _novelCountMeta =
      const VerificationMeta('novelCount');
  @override
  late final GeneratedColumn<int> novelCount = GeneratedColumn<int>(
      'novel_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, slug, description, icon, novelCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'genres';
  @override
  VerificationContext validateIntegrity(Insertable<Genre> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('novel_count')) {
      context.handle(
          _novelCountMeta,
          novelCount.isAcceptableOrUnknown(
              data['novel_count']!, _novelCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Genre map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Genre(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      novelCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}novel_count'])!,
    );
  }

  @override
  $GenresTable createAlias(String alias) {
    return $GenresTable(attachedDatabase, alias);
  }
}

class Genre extends DataClass implements Insertable<Genre> {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final int novelCount;
  const Genre(
      {required this.id,
      required this.name,
      required this.slug,
      this.description,
      this.icon,
      required this.novelCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['slug'] = Variable<String>(slug);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['novel_count'] = Variable<int>(novelCount);
    return map;
  }

  GenresCompanion toCompanion(bool nullToAbsent) {
    return GenresCompanion(
      id: Value(id),
      name: Value(name),
      slug: Value(slug),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      novelCount: Value(novelCount),
    );
  }

  factory Genre.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Genre(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      slug: serializer.fromJson<String>(json['slug']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<String?>(json['icon']),
      novelCount: serializer.fromJson<int>(json['novelCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'slug': serializer.toJson<String>(slug),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<String?>(icon),
      'novelCount': serializer.toJson<int>(novelCount),
    };
  }

  Genre copyWith(
          {String? id,
          String? name,
          String? slug,
          Value<String?> description = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          int? novelCount}) =>
      Genre(
        id: id ?? this.id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        description: description.present ? description.value : this.description,
        icon: icon.present ? icon.value : this.icon,
        novelCount: novelCount ?? this.novelCount,
      );
  Genre copyWithCompanion(GenresCompanion data) {
    return Genre(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      slug: data.slug.present ? data.slug.value : this.slug,
      description:
          data.description.present ? data.description.value : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      novelCount:
          data.novelCount.present ? data.novelCount.value : this.novelCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Genre(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('novelCount: $novelCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, slug, description, icon, novelCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Genre &&
          other.id == this.id &&
          other.name == this.name &&
          other.slug == this.slug &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.novelCount == this.novelCount);
}

class GenresCompanion extends UpdateCompanion<Genre> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> slug;
  final Value<String?> description;
  final Value<String?> icon;
  final Value<int> novelCount;
  final Value<int> rowid;
  const GenresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.slug = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.novelCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenresCompanion.insert({
    required String id,
    required String name,
    required String slug,
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.novelCount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        slug = Value(slug);
  static Insertable<Genre> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? slug,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<int>? novelCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (slug != null) 'slug': slug,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (novelCount != null) 'novel_count': novelCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GenresCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? slug,
      Value<String?>? description,
      Value<String?>? icon,
      Value<int>? novelCount,
      Value<int>? rowid}) {
    return GenresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      novelCount: novelCount ?? this.novelCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (novelCount.present) {
      map['novel_count'] = Variable<int>(novelCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('novelCount: $novelCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NovelGenresTable extends NovelGenres
    with TableInfo<$NovelGenresTable, NovelGenre> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NovelGenresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _novelIdMeta =
      const VerificationMeta('novelId');
  @override
  late final GeneratedColumn<String> novelId = GeneratedColumn<String>(
      'novel_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genreIdMeta =
      const VerificationMeta('genreId');
  @override
  late final GeneratedColumn<String> genreId = GeneratedColumn<String>(
      'genre_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [novelId, genreId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'novel_genres';
  @override
  VerificationContext validateIntegrity(Insertable<NovelGenre> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('novel_id')) {
      context.handle(_novelIdMeta,
          novelId.isAcceptableOrUnknown(data['novel_id']!, _novelIdMeta));
    } else if (isInserting) {
      context.missing(_novelIdMeta);
    }
    if (data.containsKey('genre_id')) {
      context.handle(_genreIdMeta,
          genreId.isAcceptableOrUnknown(data['genre_id']!, _genreIdMeta));
    } else if (isInserting) {
      context.missing(_genreIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {novelId, genreId};
  @override
  NovelGenre map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NovelGenre(
      novelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}novel_id'])!,
      genreId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre_id'])!,
    );
  }

  @override
  $NovelGenresTable createAlias(String alias) {
    return $NovelGenresTable(attachedDatabase, alias);
  }
}

class NovelGenre extends DataClass implements Insertable<NovelGenre> {
  final String novelId;
  final String genreId;
  const NovelGenre({required this.novelId, required this.genreId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['novel_id'] = Variable<String>(novelId);
    map['genre_id'] = Variable<String>(genreId);
    return map;
  }

  NovelGenresCompanion toCompanion(bool nullToAbsent) {
    return NovelGenresCompanion(
      novelId: Value(novelId),
      genreId: Value(genreId),
    );
  }

  factory NovelGenre.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NovelGenre(
      novelId: serializer.fromJson<String>(json['novelId']),
      genreId: serializer.fromJson<String>(json['genreId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'novelId': serializer.toJson<String>(novelId),
      'genreId': serializer.toJson<String>(genreId),
    };
  }

  NovelGenre copyWith({String? novelId, String? genreId}) => NovelGenre(
        novelId: novelId ?? this.novelId,
        genreId: genreId ?? this.genreId,
      );
  NovelGenre copyWithCompanion(NovelGenresCompanion data) {
    return NovelGenre(
      novelId: data.novelId.present ? data.novelId.value : this.novelId,
      genreId: data.genreId.present ? data.genreId.value : this.genreId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NovelGenre(')
          ..write('novelId: $novelId, ')
          ..write('genreId: $genreId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(novelId, genreId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NovelGenre &&
          other.novelId == this.novelId &&
          other.genreId == this.genreId);
}

class NovelGenresCompanion extends UpdateCompanion<NovelGenre> {
  final Value<String> novelId;
  final Value<String> genreId;
  final Value<int> rowid;
  const NovelGenresCompanion({
    this.novelId = const Value.absent(),
    this.genreId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NovelGenresCompanion.insert({
    required String novelId,
    required String genreId,
    this.rowid = const Value.absent(),
  })  : novelId = Value(novelId),
        genreId = Value(genreId);
  static Insertable<NovelGenre> custom({
    Expression<String>? novelId,
    Expression<String>? genreId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (novelId != null) 'novel_id': novelId,
      if (genreId != null) 'genre_id': genreId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NovelGenresCompanion copyWith(
      {Value<String>? novelId, Value<String>? genreId, Value<int>? rowid}) {
    return NovelGenresCompanion(
      novelId: novelId ?? this.novelId,
      genreId: genreId ?? this.genreId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (novelId.present) {
      map['novel_id'] = Variable<String>(novelId.value);
    }
    if (genreId.present) {
      map['genre_id'] = Variable<String>(genreId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NovelGenresCompanion(')
          ..write('novelId: $novelId, ')
          ..write('genreId: $genreId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersMetaTable extends ChaptersMeta
    with TableInfo<$ChaptersMetaTable, ChaptersMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _novelIdMeta =
      const VerificationMeta('novelId');
  @override
  late final GeneratedColumn<String> novelId = GeneratedColumn<String>(
      'novel_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _volumeNumberMeta =
      const VerificationMeta('volumeNumber');
  @override
  late final GeneratedColumn<int> volumeNumber = GeneratedColumn<int>(
      'volume_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _volumeTitleMeta =
      const VerificationMeta('volumeTitle');
  @override
  late final GeneratedColumn<String> volumeTitle = GeneratedColumn<String>(
      'volume_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _volumeChapterNumberMeta =
      const VerificationMeta('volumeChapterNumber');
  @override
  late final GeneratedColumn<int> volumeChapterNumber = GeneratedColumn<int>(
      'volume_chapter_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        novelId,
        number,
        title,
        volumeNumber,
        volumeTitle,
        volumeChapterNumber,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters_meta';
  @override
  VerificationContext validateIntegrity(Insertable<ChaptersMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('novel_id')) {
      context.handle(_novelIdMeta,
          novelId.isAcceptableOrUnknown(data['novel_id']!, _novelIdMeta));
    } else if (isInserting) {
      context.missing(_novelIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('volume_number')) {
      context.handle(
          _volumeNumberMeta,
          volumeNumber.isAcceptableOrUnknown(
              data['volume_number']!, _volumeNumberMeta));
    }
    if (data.containsKey('volume_title')) {
      context.handle(
          _volumeTitleMeta,
          volumeTitle.isAcceptableOrUnknown(
              data['volume_title']!, _volumeTitleMeta));
    }
    if (data.containsKey('volume_chapter_number')) {
      context.handle(
          _volumeChapterNumberMeta,
          volumeChapterNumber.isAcceptableOrUnknown(
              data['volume_chapter_number']!, _volumeChapterNumberMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChaptersMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChaptersMetaData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      novelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}novel_id'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      volumeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}volume_number']),
      volumeTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}volume_title']),
      volumeChapterNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}volume_chapter_number']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ChaptersMetaTable createAlias(String alias) {
    return $ChaptersMetaTable(attachedDatabase, alias);
  }
}

class ChaptersMetaData extends DataClass
    implements Insertable<ChaptersMetaData> {
  final String id;
  final String novelId;
  final int number;
  final String title;
  final int? volumeNumber;
  final String? volumeTitle;
  final int? volumeChapterNumber;
  final DateTime createdAt;
  const ChaptersMetaData(
      {required this.id,
      required this.novelId,
      required this.number,
      required this.title,
      this.volumeNumber,
      this.volumeTitle,
      this.volumeChapterNumber,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['novel_id'] = Variable<String>(novelId);
    map['number'] = Variable<int>(number);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || volumeNumber != null) {
      map['volume_number'] = Variable<int>(volumeNumber);
    }
    if (!nullToAbsent || volumeTitle != null) {
      map['volume_title'] = Variable<String>(volumeTitle);
    }
    if (!nullToAbsent || volumeChapterNumber != null) {
      map['volume_chapter_number'] = Variable<int>(volumeChapterNumber);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChaptersMetaCompanion toCompanion(bool nullToAbsent) {
    return ChaptersMetaCompanion(
      id: Value(id),
      novelId: Value(novelId),
      number: Value(number),
      title: Value(title),
      volumeNumber: volumeNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeNumber),
      volumeTitle: volumeTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeTitle),
      volumeChapterNumber: volumeChapterNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeChapterNumber),
      createdAt: Value(createdAt),
    );
  }

  factory ChaptersMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChaptersMetaData(
      id: serializer.fromJson<String>(json['id']),
      novelId: serializer.fromJson<String>(json['novelId']),
      number: serializer.fromJson<int>(json['number']),
      title: serializer.fromJson<String>(json['title']),
      volumeNumber: serializer.fromJson<int?>(json['volumeNumber']),
      volumeTitle: serializer.fromJson<String?>(json['volumeTitle']),
      volumeChapterNumber:
          serializer.fromJson<int?>(json['volumeChapterNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'novelId': serializer.toJson<String>(novelId),
      'number': serializer.toJson<int>(number),
      'title': serializer.toJson<String>(title),
      'volumeNumber': serializer.toJson<int?>(volumeNumber),
      'volumeTitle': serializer.toJson<String?>(volumeTitle),
      'volumeChapterNumber': serializer.toJson<int?>(volumeChapterNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChaptersMetaData copyWith(
          {String? id,
          String? novelId,
          int? number,
          String? title,
          Value<int?> volumeNumber = const Value.absent(),
          Value<String?> volumeTitle = const Value.absent(),
          Value<int?> volumeChapterNumber = const Value.absent(),
          DateTime? createdAt}) =>
      ChaptersMetaData(
        id: id ?? this.id,
        novelId: novelId ?? this.novelId,
        number: number ?? this.number,
        title: title ?? this.title,
        volumeNumber:
            volumeNumber.present ? volumeNumber.value : this.volumeNumber,
        volumeTitle: volumeTitle.present ? volumeTitle.value : this.volumeTitle,
        volumeChapterNumber: volumeChapterNumber.present
            ? volumeChapterNumber.value
            : this.volumeChapterNumber,
        createdAt: createdAt ?? this.createdAt,
      );
  ChaptersMetaData copyWithCompanion(ChaptersMetaCompanion data) {
    return ChaptersMetaData(
      id: data.id.present ? data.id.value : this.id,
      novelId: data.novelId.present ? data.novelId.value : this.novelId,
      number: data.number.present ? data.number.value : this.number,
      title: data.title.present ? data.title.value : this.title,
      volumeNumber: data.volumeNumber.present
          ? data.volumeNumber.value
          : this.volumeNumber,
      volumeTitle:
          data.volumeTitle.present ? data.volumeTitle.value : this.volumeTitle,
      volumeChapterNumber: data.volumeChapterNumber.present
          ? data.volumeChapterNumber.value
          : this.volumeChapterNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersMetaData(')
          ..write('id: $id, ')
          ..write('novelId: $novelId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('volumeNumber: $volumeNumber, ')
          ..write('volumeTitle: $volumeTitle, ')
          ..write('volumeChapterNumber: $volumeChapterNumber, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, novelId, number, title, volumeNumber,
      volumeTitle, volumeChapterNumber, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChaptersMetaData &&
          other.id == this.id &&
          other.novelId == this.novelId &&
          other.number == this.number &&
          other.title == this.title &&
          other.volumeNumber == this.volumeNumber &&
          other.volumeTitle == this.volumeTitle &&
          other.volumeChapterNumber == this.volumeChapterNumber &&
          other.createdAt == this.createdAt);
}

class ChaptersMetaCompanion extends UpdateCompanion<ChaptersMetaData> {
  final Value<String> id;
  final Value<String> novelId;
  final Value<int> number;
  final Value<String> title;
  final Value<int?> volumeNumber;
  final Value<String?> volumeTitle;
  final Value<int?> volumeChapterNumber;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChaptersMetaCompanion({
    this.id = const Value.absent(),
    this.novelId = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.volumeNumber = const Value.absent(),
    this.volumeTitle = const Value.absent(),
    this.volumeChapterNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersMetaCompanion.insert({
    required String id,
    required String novelId,
    required int number,
    required String title,
    this.volumeNumber = const Value.absent(),
    this.volumeTitle = const Value.absent(),
    this.volumeChapterNumber = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        novelId = Value(novelId),
        number = Value(number),
        title = Value(title),
        createdAt = Value(createdAt);
  static Insertable<ChaptersMetaData> custom({
    Expression<String>? id,
    Expression<String>? novelId,
    Expression<int>? number,
    Expression<String>? title,
    Expression<int>? volumeNumber,
    Expression<String>? volumeTitle,
    Expression<int>? volumeChapterNumber,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (novelId != null) 'novel_id': novelId,
      if (number != null) 'number': number,
      if (title != null) 'title': title,
      if (volumeNumber != null) 'volume_number': volumeNumber,
      if (volumeTitle != null) 'volume_title': volumeTitle,
      if (volumeChapterNumber != null)
        'volume_chapter_number': volumeChapterNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersMetaCompanion copyWith(
      {Value<String>? id,
      Value<String>? novelId,
      Value<int>? number,
      Value<String>? title,
      Value<int?>? volumeNumber,
      Value<String?>? volumeTitle,
      Value<int?>? volumeChapterNumber,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ChaptersMetaCompanion(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      number: number ?? this.number,
      title: title ?? this.title,
      volumeNumber: volumeNumber ?? this.volumeNumber,
      volumeTitle: volumeTitle ?? this.volumeTitle,
      volumeChapterNumber: volumeChapterNumber ?? this.volumeChapterNumber,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (novelId.present) {
      map['novel_id'] = Variable<String>(novelId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (volumeNumber.present) {
      map['volume_number'] = Variable<int>(volumeNumber.value);
    }
    if (volumeTitle.present) {
      map['volume_title'] = Variable<String>(volumeTitle.value);
    }
    if (volumeChapterNumber.present) {
      map['volume_chapter_number'] = Variable<int>(volumeChapterNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersMetaCompanion(')
          ..write('id: $id, ')
          ..write('novelId: $novelId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('volumeNumber: $volumeNumber, ')
          ..write('volumeTitle: $volumeTitle, ')
          ..write('volumeChapterNumber: $volumeChapterNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChapterContentsTable extends ChapterContents
    with TableInfo<$ChapterContentsTable, ChapterContent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChapterContentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _novelIdMeta =
      const VerificationMeta('novelId');
  @override
  late final GeneratedColumn<String> novelId = GeneratedColumn<String>(
      'novel_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _prevChapterIdMeta =
      const VerificationMeta('prevChapterId');
  @override
  late final GeneratedColumn<String> prevChapterId = GeneratedColumn<String>(
      'prev_chapter_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _prevChapterNumberMeta =
      const VerificationMeta('prevChapterNumber');
  @override
  late final GeneratedColumn<int> prevChapterNumber = GeneratedColumn<int>(
      'prev_chapter_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nextChapterIdMeta =
      const VerificationMeta('nextChapterId');
  @override
  late final GeneratedColumn<String> nextChapterId = GeneratedColumn<String>(
      'next_chapter_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextChapterNumberMeta =
      const VerificationMeta('nextChapterNumber');
  @override
  late final GeneratedColumn<int> nextChapterNumber = GeneratedColumn<int>(
      'next_chapter_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _volumeTitleMeta =
      const VerificationMeta('volumeTitle');
  @override
  late final GeneratedColumn<String> volumeTitle = GeneratedColumn<String>(
      'volume_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDownloadedMeta =
      const VerificationMeta('isDownloaded');
  @override
  late final GeneratedColumn<bool> isDownloaded = GeneratedColumn<bool>(
      'is_downloaded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_downloaded" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        chapterId,
        novelId,
        number,
        title,
        content,
        prevChapterId,
        prevChapterNumber,
        nextChapterId,
        nextChapterNumber,
        volumeTitle,
        isDownloaded,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapter_contents';
  @override
  VerificationContext validateIntegrity(Insertable<ChapterContent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('novel_id')) {
      context.handle(_novelIdMeta,
          novelId.isAcceptableOrUnknown(data['novel_id']!, _novelIdMeta));
    } else if (isInserting) {
      context.missing(_novelIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('prev_chapter_id')) {
      context.handle(
          _prevChapterIdMeta,
          prevChapterId.isAcceptableOrUnknown(
              data['prev_chapter_id']!, _prevChapterIdMeta));
    }
    if (data.containsKey('prev_chapter_number')) {
      context.handle(
          _prevChapterNumberMeta,
          prevChapterNumber.isAcceptableOrUnknown(
              data['prev_chapter_number']!, _prevChapterNumberMeta));
    }
    if (data.containsKey('next_chapter_id')) {
      context.handle(
          _nextChapterIdMeta,
          nextChapterId.isAcceptableOrUnknown(
              data['next_chapter_id']!, _nextChapterIdMeta));
    }
    if (data.containsKey('next_chapter_number')) {
      context.handle(
          _nextChapterNumberMeta,
          nextChapterNumber.isAcceptableOrUnknown(
              data['next_chapter_number']!, _nextChapterNumberMeta));
    }
    if (data.containsKey('volume_title')) {
      context.handle(
          _volumeTitleMeta,
          volumeTitle.isAcceptableOrUnknown(
              data['volume_title']!, _volumeTitleMeta));
    }
    if (data.containsKey('is_downloaded')) {
      context.handle(
          _isDownloadedMeta,
          isDownloaded.isAcceptableOrUnknown(
              data['is_downloaded']!, _isDownloadedMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chapterId};
  @override
  ChapterContent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterContent(
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter_id'])!,
      novelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}novel_id'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      prevChapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prev_chapter_id']),
      prevChapterNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}prev_chapter_number']),
      nextChapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}next_chapter_id']),
      nextChapterNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}next_chapter_number']),
      volumeTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}volume_title']),
      isDownloaded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_downloaded'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $ChapterContentsTable createAlias(String alias) {
    return $ChapterContentsTable(attachedDatabase, alias);
  }
}

class ChapterContent extends DataClass implements Insertable<ChapterContent> {
  final String chapterId;
  final String novelId;
  final int number;
  final String title;
  final String content;
  final String? prevChapterId;
  final int? prevChapterNumber;
  final String? nextChapterId;
  final int? nextChapterNumber;
  final String? volumeTitle;
  final bool isDownloaded;
  final DateTime cachedAt;
  const ChapterContent(
      {required this.chapterId,
      required this.novelId,
      required this.number,
      required this.title,
      required this.content,
      this.prevChapterId,
      this.prevChapterNumber,
      this.nextChapterId,
      this.nextChapterNumber,
      this.volumeTitle,
      required this.isDownloaded,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chapter_id'] = Variable<String>(chapterId);
    map['novel_id'] = Variable<String>(novelId);
    map['number'] = Variable<int>(number);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || prevChapterId != null) {
      map['prev_chapter_id'] = Variable<String>(prevChapterId);
    }
    if (!nullToAbsent || prevChapterNumber != null) {
      map['prev_chapter_number'] = Variable<int>(prevChapterNumber);
    }
    if (!nullToAbsent || nextChapterId != null) {
      map['next_chapter_id'] = Variable<String>(nextChapterId);
    }
    if (!nullToAbsent || nextChapterNumber != null) {
      map['next_chapter_number'] = Variable<int>(nextChapterNumber);
    }
    if (!nullToAbsent || volumeTitle != null) {
      map['volume_title'] = Variable<String>(volumeTitle);
    }
    map['is_downloaded'] = Variable<bool>(isDownloaded);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ChapterContentsCompanion toCompanion(bool nullToAbsent) {
    return ChapterContentsCompanion(
      chapterId: Value(chapterId),
      novelId: Value(novelId),
      number: Value(number),
      title: Value(title),
      content: Value(content),
      prevChapterId: prevChapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(prevChapterId),
      prevChapterNumber: prevChapterNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(prevChapterNumber),
      nextChapterId: nextChapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(nextChapterId),
      nextChapterNumber: nextChapterNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(nextChapterNumber),
      volumeTitle: volumeTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeTitle),
      isDownloaded: Value(isDownloaded),
      cachedAt: Value(cachedAt),
    );
  }

  factory ChapterContent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterContent(
      chapterId: serializer.fromJson<String>(json['chapterId']),
      novelId: serializer.fromJson<String>(json['novelId']),
      number: serializer.fromJson<int>(json['number']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      prevChapterId: serializer.fromJson<String?>(json['prevChapterId']),
      prevChapterNumber: serializer.fromJson<int?>(json['prevChapterNumber']),
      nextChapterId: serializer.fromJson<String?>(json['nextChapterId']),
      nextChapterNumber: serializer.fromJson<int?>(json['nextChapterNumber']),
      volumeTitle: serializer.fromJson<String?>(json['volumeTitle']),
      isDownloaded: serializer.fromJson<bool>(json['isDownloaded']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chapterId': serializer.toJson<String>(chapterId),
      'novelId': serializer.toJson<String>(novelId),
      'number': serializer.toJson<int>(number),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'prevChapterId': serializer.toJson<String?>(prevChapterId),
      'prevChapterNumber': serializer.toJson<int?>(prevChapterNumber),
      'nextChapterId': serializer.toJson<String?>(nextChapterId),
      'nextChapterNumber': serializer.toJson<int?>(nextChapterNumber),
      'volumeTitle': serializer.toJson<String?>(volumeTitle),
      'isDownloaded': serializer.toJson<bool>(isDownloaded),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  ChapterContent copyWith(
          {String? chapterId,
          String? novelId,
          int? number,
          String? title,
          String? content,
          Value<String?> prevChapterId = const Value.absent(),
          Value<int?> prevChapterNumber = const Value.absent(),
          Value<String?> nextChapterId = const Value.absent(),
          Value<int?> nextChapterNumber = const Value.absent(),
          Value<String?> volumeTitle = const Value.absent(),
          bool? isDownloaded,
          DateTime? cachedAt}) =>
      ChapterContent(
        chapterId: chapterId ?? this.chapterId,
        novelId: novelId ?? this.novelId,
        number: number ?? this.number,
        title: title ?? this.title,
        content: content ?? this.content,
        prevChapterId:
            prevChapterId.present ? prevChapterId.value : this.prevChapterId,
        prevChapterNumber: prevChapterNumber.present
            ? prevChapterNumber.value
            : this.prevChapterNumber,
        nextChapterId:
            nextChapterId.present ? nextChapterId.value : this.nextChapterId,
        nextChapterNumber: nextChapterNumber.present
            ? nextChapterNumber.value
            : this.nextChapterNumber,
        volumeTitle: volumeTitle.present ? volumeTitle.value : this.volumeTitle,
        isDownloaded: isDownloaded ?? this.isDownloaded,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  ChapterContent copyWithCompanion(ChapterContentsCompanion data) {
    return ChapterContent(
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      novelId: data.novelId.present ? data.novelId.value : this.novelId,
      number: data.number.present ? data.number.value : this.number,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      prevChapterId: data.prevChapterId.present
          ? data.prevChapterId.value
          : this.prevChapterId,
      prevChapterNumber: data.prevChapterNumber.present
          ? data.prevChapterNumber.value
          : this.prevChapterNumber,
      nextChapterId: data.nextChapterId.present
          ? data.nextChapterId.value
          : this.nextChapterId,
      nextChapterNumber: data.nextChapterNumber.present
          ? data.nextChapterNumber.value
          : this.nextChapterNumber,
      volumeTitle:
          data.volumeTitle.present ? data.volumeTitle.value : this.volumeTitle,
      isDownloaded: data.isDownloaded.present
          ? data.isDownloaded.value
          : this.isDownloaded,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterContent(')
          ..write('chapterId: $chapterId, ')
          ..write('novelId: $novelId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('prevChapterId: $prevChapterId, ')
          ..write('prevChapterNumber: $prevChapterNumber, ')
          ..write('nextChapterId: $nextChapterId, ')
          ..write('nextChapterNumber: $nextChapterNumber, ')
          ..write('volumeTitle: $volumeTitle, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      chapterId,
      novelId,
      number,
      title,
      content,
      prevChapterId,
      prevChapterNumber,
      nextChapterId,
      nextChapterNumber,
      volumeTitle,
      isDownloaded,
      cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterContent &&
          other.chapterId == this.chapterId &&
          other.novelId == this.novelId &&
          other.number == this.number &&
          other.title == this.title &&
          other.content == this.content &&
          other.prevChapterId == this.prevChapterId &&
          other.prevChapterNumber == this.prevChapterNumber &&
          other.nextChapterId == this.nextChapterId &&
          other.nextChapterNumber == this.nextChapterNumber &&
          other.volumeTitle == this.volumeTitle &&
          other.isDownloaded == this.isDownloaded &&
          other.cachedAt == this.cachedAt);
}

class ChapterContentsCompanion extends UpdateCompanion<ChapterContent> {
  final Value<String> chapterId;
  final Value<String> novelId;
  final Value<int> number;
  final Value<String> title;
  final Value<String> content;
  final Value<String?> prevChapterId;
  final Value<int?> prevChapterNumber;
  final Value<String?> nextChapterId;
  final Value<int?> nextChapterNumber;
  final Value<String?> volumeTitle;
  final Value<bool> isDownloaded;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const ChapterContentsCompanion({
    this.chapterId = const Value.absent(),
    this.novelId = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.prevChapterId = const Value.absent(),
    this.prevChapterNumber = const Value.absent(),
    this.nextChapterId = const Value.absent(),
    this.nextChapterNumber = const Value.absent(),
    this.volumeTitle = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChapterContentsCompanion.insert({
    required String chapterId,
    required String novelId,
    required int number,
    required String title,
    required String content,
    this.prevChapterId = const Value.absent(),
    this.prevChapterNumber = const Value.absent(),
    this.nextChapterId = const Value.absent(),
    this.nextChapterNumber = const Value.absent(),
    this.volumeTitle = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : chapterId = Value(chapterId),
        novelId = Value(novelId),
        number = Value(number),
        title = Value(title),
        content = Value(content);
  static Insertable<ChapterContent> custom({
    Expression<String>? chapterId,
    Expression<String>? novelId,
    Expression<int>? number,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? prevChapterId,
    Expression<int>? prevChapterNumber,
    Expression<String>? nextChapterId,
    Expression<int>? nextChapterNumber,
    Expression<String>? volumeTitle,
    Expression<bool>? isDownloaded,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chapterId != null) 'chapter_id': chapterId,
      if (novelId != null) 'novel_id': novelId,
      if (number != null) 'number': number,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (prevChapterId != null) 'prev_chapter_id': prevChapterId,
      if (prevChapterNumber != null) 'prev_chapter_number': prevChapterNumber,
      if (nextChapterId != null) 'next_chapter_id': nextChapterId,
      if (nextChapterNumber != null) 'next_chapter_number': nextChapterNumber,
      if (volumeTitle != null) 'volume_title': volumeTitle,
      if (isDownloaded != null) 'is_downloaded': isDownloaded,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChapterContentsCompanion copyWith(
      {Value<String>? chapterId,
      Value<String>? novelId,
      Value<int>? number,
      Value<String>? title,
      Value<String>? content,
      Value<String?>? prevChapterId,
      Value<int?>? prevChapterNumber,
      Value<String?>? nextChapterId,
      Value<int?>? nextChapterNumber,
      Value<String?>? volumeTitle,
      Value<bool>? isDownloaded,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return ChapterContentsCompanion(
      chapterId: chapterId ?? this.chapterId,
      novelId: novelId ?? this.novelId,
      number: number ?? this.number,
      title: title ?? this.title,
      content: content ?? this.content,
      prevChapterId: prevChapterId ?? this.prevChapterId,
      prevChapterNumber: prevChapterNumber ?? this.prevChapterNumber,
      nextChapterId: nextChapterId ?? this.nextChapterId,
      nextChapterNumber: nextChapterNumber ?? this.nextChapterNumber,
      volumeTitle: volumeTitle ?? this.volumeTitle,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (novelId.present) {
      map['novel_id'] = Variable<String>(novelId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (prevChapterId.present) {
      map['prev_chapter_id'] = Variable<String>(prevChapterId.value);
    }
    if (prevChapterNumber.present) {
      map['prev_chapter_number'] = Variable<int>(prevChapterNumber.value);
    }
    if (nextChapterId.present) {
      map['next_chapter_id'] = Variable<String>(nextChapterId.value);
    }
    if (nextChapterNumber.present) {
      map['next_chapter_number'] = Variable<int>(nextChapterNumber.value);
    }
    if (volumeTitle.present) {
      map['volume_title'] = Variable<String>(volumeTitle.value);
    }
    if (isDownloaded.present) {
      map['is_downloaded'] = Variable<bool>(isDownloaded.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChapterContentsCompanion(')
          ..write('chapterId: $chapterId, ')
          ..write('novelId: $novelId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('prevChapterId: $prevChapterId, ')
          ..write('prevChapterNumber: $prevChapterNumber, ')
          ..write('nextChapterId: $nextChapterId, ')
          ..write('nextChapterNumber: $nextChapterNumber, ')
          ..write('volumeTitle: $volumeTitle, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _novelIdMeta =
      const VerificationMeta('novelId');
  @override
  late final GeneratedColumn<String> novelId = GeneratedColumn<String>(
      'novel_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shelfStatusMeta =
      const VerificationMeta('shelfStatus');
  @override
  late final GeneratedColumn<String> shelfStatus = GeneratedColumn<String>(
      'shelf_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastChapterIdMeta =
      const VerificationMeta('lastChapterId');
  @override
  late final GeneratedColumn<String> lastChapterId = GeneratedColumn<String>(
      'last_chapter_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastChapterNumberMeta =
      const VerificationMeta('lastChapterNumber');
  @override
  late final GeneratedColumn<int> lastChapterNumber = GeneratedColumn<int>(
      'last_chapter_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _readChaptersJsonMeta =
      const VerificationMeta('readChaptersJson');
  @override
  late final GeneratedColumn<String> readChaptersJson = GeneratedColumn<String>(
      'read_chapters_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _markedAsReadMeta =
      const VerificationMeta('markedAsRead');
  @override
  late final GeneratedColumn<bool> markedAsRead = GeneratedColumn<bool>(
      'marked_as_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("marked_as_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        novelId,
        type,
        shelfStatus,
        lastChapterId,
        lastChapterNumber,
        readChaptersJson,
        markedAsRead,
        updatedAt,
        pendingSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<Bookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('novel_id')) {
      context.handle(_novelIdMeta,
          novelId.isAcceptableOrUnknown(data['novel_id']!, _novelIdMeta));
    } else if (isInserting) {
      context.missing(_novelIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('shelf_status')) {
      context.handle(
          _shelfStatusMeta,
          shelfStatus.isAcceptableOrUnknown(
              data['shelf_status']!, _shelfStatusMeta));
    } else if (isInserting) {
      context.missing(_shelfStatusMeta);
    }
    if (data.containsKey('last_chapter_id')) {
      context.handle(
          _lastChapterIdMeta,
          lastChapterId.isAcceptableOrUnknown(
              data['last_chapter_id']!, _lastChapterIdMeta));
    }
    if (data.containsKey('last_chapter_number')) {
      context.handle(
          _lastChapterNumberMeta,
          lastChapterNumber.isAcceptableOrUnknown(
              data['last_chapter_number']!, _lastChapterNumberMeta));
    }
    if (data.containsKey('read_chapters_json')) {
      context.handle(
          _readChaptersJsonMeta,
          readChaptersJson.isAcceptableOrUnknown(
              data['read_chapters_json']!, _readChaptersJsonMeta));
    }
    if (data.containsKey('marked_as_read')) {
      context.handle(
          _markedAsReadMeta,
          markedAsRead.isAcceptableOrUnknown(
              data['marked_as_read']!, _markedAsReadMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      novelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}novel_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      shelfStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shelf_status'])!,
      lastChapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_chapter_id']),
      lastChapterNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_chapter_number']),
      readChaptersJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}read_chapters_json'])!,
      markedAsRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}marked_as_read'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String id;
  final String novelId;
  final String type;
  final String shelfStatus;
  final String? lastChapterId;
  final int? lastChapterNumber;
  final String readChaptersJson;
  final bool markedAsRead;
  final DateTime updatedAt;
  final bool pendingSync;
  const Bookmark(
      {required this.id,
      required this.novelId,
      required this.type,
      required this.shelfStatus,
      this.lastChapterId,
      this.lastChapterNumber,
      required this.readChaptersJson,
      required this.markedAsRead,
      required this.updatedAt,
      required this.pendingSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['novel_id'] = Variable<String>(novelId);
    map['type'] = Variable<String>(type);
    map['shelf_status'] = Variable<String>(shelfStatus);
    if (!nullToAbsent || lastChapterId != null) {
      map['last_chapter_id'] = Variable<String>(lastChapterId);
    }
    if (!nullToAbsent || lastChapterNumber != null) {
      map['last_chapter_number'] = Variable<int>(lastChapterNumber);
    }
    map['read_chapters_json'] = Variable<String>(readChaptersJson);
    map['marked_as_read'] = Variable<bool>(markedAsRead);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      novelId: Value(novelId),
      type: Value(type),
      shelfStatus: Value(shelfStatus),
      lastChapterId: lastChapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastChapterId),
      lastChapterNumber: lastChapterNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(lastChapterNumber),
      readChaptersJson: Value(readChaptersJson),
      markedAsRead: Value(markedAsRead),
      updatedAt: Value(updatedAt),
      pendingSync: Value(pendingSync),
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<String>(json['id']),
      novelId: serializer.fromJson<String>(json['novelId']),
      type: serializer.fromJson<String>(json['type']),
      shelfStatus: serializer.fromJson<String>(json['shelfStatus']),
      lastChapterId: serializer.fromJson<String?>(json['lastChapterId']),
      lastChapterNumber: serializer.fromJson<int?>(json['lastChapterNumber']),
      readChaptersJson: serializer.fromJson<String>(json['readChaptersJson']),
      markedAsRead: serializer.fromJson<bool>(json['markedAsRead']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'novelId': serializer.toJson<String>(novelId),
      'type': serializer.toJson<String>(type),
      'shelfStatus': serializer.toJson<String>(shelfStatus),
      'lastChapterId': serializer.toJson<String?>(lastChapterId),
      'lastChapterNumber': serializer.toJson<int?>(lastChapterNumber),
      'readChaptersJson': serializer.toJson<String>(readChaptersJson),
      'markedAsRead': serializer.toJson<bool>(markedAsRead),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  Bookmark copyWith(
          {String? id,
          String? novelId,
          String? type,
          String? shelfStatus,
          Value<String?> lastChapterId = const Value.absent(),
          Value<int?> lastChapterNumber = const Value.absent(),
          String? readChaptersJson,
          bool? markedAsRead,
          DateTime? updatedAt,
          bool? pendingSync}) =>
      Bookmark(
        id: id ?? this.id,
        novelId: novelId ?? this.novelId,
        type: type ?? this.type,
        shelfStatus: shelfStatus ?? this.shelfStatus,
        lastChapterId:
            lastChapterId.present ? lastChapterId.value : this.lastChapterId,
        lastChapterNumber: lastChapterNumber.present
            ? lastChapterNumber.value
            : this.lastChapterNumber,
        readChaptersJson: readChaptersJson ?? this.readChaptersJson,
        markedAsRead: markedAsRead ?? this.markedAsRead,
        updatedAt: updatedAt ?? this.updatedAt,
        pendingSync: pendingSync ?? this.pendingSync,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      novelId: data.novelId.present ? data.novelId.value : this.novelId,
      type: data.type.present ? data.type.value : this.type,
      shelfStatus:
          data.shelfStatus.present ? data.shelfStatus.value : this.shelfStatus,
      lastChapterId: data.lastChapterId.present
          ? data.lastChapterId.value
          : this.lastChapterId,
      lastChapterNumber: data.lastChapterNumber.present
          ? data.lastChapterNumber.value
          : this.lastChapterNumber,
      readChaptersJson: data.readChaptersJson.present
          ? data.readChaptersJson.value
          : this.readChaptersJson,
      markedAsRead: data.markedAsRead.present
          ? data.markedAsRead.value
          : this.markedAsRead,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('novelId: $novelId, ')
          ..write('type: $type, ')
          ..write('shelfStatus: $shelfStatus, ')
          ..write('lastChapterId: $lastChapterId, ')
          ..write('lastChapterNumber: $lastChapterNumber, ')
          ..write('readChaptersJson: $readChaptersJson, ')
          ..write('markedAsRead: $markedAsRead, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      novelId,
      type,
      shelfStatus,
      lastChapterId,
      lastChapterNumber,
      readChaptersJson,
      markedAsRead,
      updatedAt,
      pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.novelId == this.novelId &&
          other.type == this.type &&
          other.shelfStatus == this.shelfStatus &&
          other.lastChapterId == this.lastChapterId &&
          other.lastChapterNumber == this.lastChapterNumber &&
          other.readChaptersJson == this.readChaptersJson &&
          other.markedAsRead == this.markedAsRead &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<String> novelId;
  final Value<String> type;
  final Value<String> shelfStatus;
  final Value<String?> lastChapterId;
  final Value<int?> lastChapterNumber;
  final Value<String> readChaptersJson;
  final Value<bool> markedAsRead;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingSync;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.novelId = const Value.absent(),
    this.type = const Value.absent(),
    this.shelfStatus = const Value.absent(),
    this.lastChapterId = const Value.absent(),
    this.lastChapterNumber = const Value.absent(),
    this.readChaptersJson = const Value.absent(),
    this.markedAsRead = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String novelId,
    required String type,
    required String shelfStatus,
    this.lastChapterId = const Value.absent(),
    this.lastChapterNumber = const Value.absent(),
    this.readChaptersJson = const Value.absent(),
    this.markedAsRead = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        novelId = Value(novelId),
        type = Value(type),
        shelfStatus = Value(shelfStatus);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<String>? novelId,
    Expression<String>? type,
    Expression<String>? shelfStatus,
    Expression<String>? lastChapterId,
    Expression<int>? lastChapterNumber,
    Expression<String>? readChaptersJson,
    Expression<bool>? markedAsRead,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (novelId != null) 'novel_id': novelId,
      if (type != null) 'type': type,
      if (shelfStatus != null) 'shelf_status': shelfStatus,
      if (lastChapterId != null) 'last_chapter_id': lastChapterId,
      if (lastChapterNumber != null) 'last_chapter_number': lastChapterNumber,
      if (readChaptersJson != null) 'read_chapters_json': readChaptersJson,
      if (markedAsRead != null) 'marked_as_read': markedAsRead,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith(
      {Value<String>? id,
      Value<String>? novelId,
      Value<String>? type,
      Value<String>? shelfStatus,
      Value<String?>? lastChapterId,
      Value<int?>? lastChapterNumber,
      Value<String>? readChaptersJson,
      Value<bool>? markedAsRead,
      Value<DateTime>? updatedAt,
      Value<bool>? pendingSync,
      Value<int>? rowid}) {
    return BookmarksCompanion(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      type: type ?? this.type,
      shelfStatus: shelfStatus ?? this.shelfStatus,
      lastChapterId: lastChapterId ?? this.lastChapterId,
      lastChapterNumber: lastChapterNumber ?? this.lastChapterNumber,
      readChaptersJson: readChaptersJson ?? this.readChaptersJson,
      markedAsRead: markedAsRead ?? this.markedAsRead,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (novelId.present) {
      map['novel_id'] = Variable<String>(novelId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (shelfStatus.present) {
      map['shelf_status'] = Variable<String>(shelfStatus.value);
    }
    if (lastChapterId.present) {
      map['last_chapter_id'] = Variable<String>(lastChapterId.value);
    }
    if (lastChapterNumber.present) {
      map['last_chapter_number'] = Variable<int>(lastChapterNumber.value);
    }
    if (readChaptersJson.present) {
      map['read_chapters_json'] = Variable<String>(readChaptersJson.value);
    }
    if (markedAsRead.present) {
      map['marked_as_read'] = Variable<bool>(markedAsRead.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('novelId: $novelId, ')
          ..write('type: $type, ')
          ..write('shelfStatus: $shelfStatus, ')
          ..write('lastChapterId: $lastChapterId, ')
          ..write('lastChapterNumber: $lastChapterNumber, ')
          ..write('readChaptersJson: $readChaptersJson, ')
          ..write('markedAsRead: $markedAsRead, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _novelIdMeta =
      const VerificationMeta('novelId');
  @override
  late final GeneratedColumn<String> novelId = GeneratedColumn<String>(
      'novel_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalChaptersMeta =
      const VerificationMeta('totalChapters');
  @override
  late final GeneratedColumn<int> totalChapters = GeneratedColumn<int>(
      'total_chapters', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _downloadedChaptersMeta =
      const VerificationMeta('downloadedChapters');
  @override
  late final GeneratedColumn<int> downloadedChapters = GeneratedColumn<int>(
      'downloaded_chapters', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _bytesSizeMeta =
      const VerificationMeta('bytesSize');
  @override
  late final GeneratedColumn<int> bytesSize = GeneratedColumn<int>(
      'bytes_size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        novelId,
        status,
        totalChapters,
        downloadedChapters,
        bytesSize,
        errorMessage,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(Insertable<Download> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('novel_id')) {
      context.handle(_novelIdMeta,
          novelId.isAcceptableOrUnknown(data['novel_id']!, _novelIdMeta));
    } else if (isInserting) {
      context.missing(_novelIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_chapters')) {
      context.handle(
          _totalChaptersMeta,
          totalChapters.isAcceptableOrUnknown(
              data['total_chapters']!, _totalChaptersMeta));
    }
    if (data.containsKey('downloaded_chapters')) {
      context.handle(
          _downloadedChaptersMeta,
          downloadedChapters.isAcceptableOrUnknown(
              data['downloaded_chapters']!, _downloadedChaptersMeta));
    }
    if (data.containsKey('bytes_size')) {
      context.handle(_bytesSizeMeta,
          bytesSize.isAcceptableOrUnknown(data['bytes_size']!, _bytesSizeMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {novelId};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      novelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}novel_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      totalChapters: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_chapters'])!,
      downloadedChapters: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}downloaded_chapters'])!,
      bytesSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes_size'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class Download extends DataClass implements Insertable<Download> {
  final String novelId;
  final String status;
  final int totalChapters;
  final int downloadedChapters;
  final int bytesSize;
  final String? errorMessage;
  final DateTime updatedAt;
  const Download(
      {required this.novelId,
      required this.status,
      required this.totalChapters,
      required this.downloadedChapters,
      required this.bytesSize,
      this.errorMessage,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['novel_id'] = Variable<String>(novelId);
    map['status'] = Variable<String>(status);
    map['total_chapters'] = Variable<int>(totalChapters);
    map['downloaded_chapters'] = Variable<int>(downloadedChapters);
    map['bytes_size'] = Variable<int>(bytesSize);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      novelId: Value(novelId),
      status: Value(status),
      totalChapters: Value(totalChapters),
      downloadedChapters: Value(downloadedChapters),
      bytesSize: Value(bytesSize),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      updatedAt: Value(updatedAt),
    );
  }

  factory Download.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      novelId: serializer.fromJson<String>(json['novelId']),
      status: serializer.fromJson<String>(json['status']),
      totalChapters: serializer.fromJson<int>(json['totalChapters']),
      downloadedChapters: serializer.fromJson<int>(json['downloadedChapters']),
      bytesSize: serializer.fromJson<int>(json['bytesSize']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'novelId': serializer.toJson<String>(novelId),
      'status': serializer.toJson<String>(status),
      'totalChapters': serializer.toJson<int>(totalChapters),
      'downloadedChapters': serializer.toJson<int>(downloadedChapters),
      'bytesSize': serializer.toJson<int>(bytesSize),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Download copyWith(
          {String? novelId,
          String? status,
          int? totalChapters,
          int? downloadedChapters,
          int? bytesSize,
          Value<String?> errorMessage = const Value.absent(),
          DateTime? updatedAt}) =>
      Download(
        novelId: novelId ?? this.novelId,
        status: status ?? this.status,
        totalChapters: totalChapters ?? this.totalChapters,
        downloadedChapters: downloadedChapters ?? this.downloadedChapters,
        bytesSize: bytesSize ?? this.bytesSize,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      novelId: data.novelId.present ? data.novelId.value : this.novelId,
      status: data.status.present ? data.status.value : this.status,
      totalChapters: data.totalChapters.present
          ? data.totalChapters.value
          : this.totalChapters,
      downloadedChapters: data.downloadedChapters.present
          ? data.downloadedChapters.value
          : this.downloadedChapters,
      bytesSize: data.bytesSize.present ? data.bytesSize.value : this.bytesSize,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('novelId: $novelId, ')
          ..write('status: $status, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('downloadedChapters: $downloadedChapters, ')
          ..write('bytesSize: $bytesSize, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(novelId, status, totalChapters,
      downloadedChapters, bytesSize, errorMessage, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.novelId == this.novelId &&
          other.status == this.status &&
          other.totalChapters == this.totalChapters &&
          other.downloadedChapters == this.downloadedChapters &&
          other.bytesSize == this.bytesSize &&
          other.errorMessage == this.errorMessage &&
          other.updatedAt == this.updatedAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<String> novelId;
  final Value<String> status;
  final Value<int> totalChapters;
  final Value<int> downloadedChapters;
  final Value<int> bytesSize;
  final Value<String?> errorMessage;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.novelId = const Value.absent(),
    this.status = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.downloadedChapters = const Value.absent(),
    this.bytesSize = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String novelId,
    required String status,
    this.totalChapters = const Value.absent(),
    this.downloadedChapters = const Value.absent(),
    this.bytesSize = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : novelId = Value(novelId),
        status = Value(status);
  static Insertable<Download> custom({
    Expression<String>? novelId,
    Expression<String>? status,
    Expression<int>? totalChapters,
    Expression<int>? downloadedChapters,
    Expression<int>? bytesSize,
    Expression<String>? errorMessage,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (novelId != null) 'novel_id': novelId,
      if (status != null) 'status': status,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (downloadedChapters != null) 'downloaded_chapters': downloadedChapters,
      if (bytesSize != null) 'bytes_size': bytesSize,
      if (errorMessage != null) 'error_message': errorMessage,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith(
      {Value<String>? novelId,
      Value<String>? status,
      Value<int>? totalChapters,
      Value<int>? downloadedChapters,
      Value<int>? bytesSize,
      Value<String?>? errorMessage,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DownloadsCompanion(
      novelId: novelId ?? this.novelId,
      status: status ?? this.status,
      totalChapters: totalChapters ?? this.totalChapters,
      downloadedChapters: downloadedChapters ?? this.downloadedChapters,
      bytesSize: bytesSize ?? this.bytesSize,
      errorMessage: errorMessage ?? this.errorMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (novelId.present) {
      map['novel_id'] = Variable<String>(novelId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalChapters.present) {
      map['total_chapters'] = Variable<int>(totalChapters.value);
    }
    if (downloadedChapters.present) {
      map['downloaded_chapters'] = Variable<int>(downloadedChapters.value);
    }
    if (bytesSize.present) {
      map['bytes_size'] = Variable<int>(bytesSize.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('novelId: $novelId, ')
          ..write('status: $status, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('downloadedChapters: $downloadedChapters, ')
          ..write('bytesSize: $bytesSize, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at'])!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String key;
  final DateTime lastSyncedAt;
  const SyncMetaData({required this.key, required this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      key: Value(key),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory SyncMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      key: serializer.fromJson<String>(json['key']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
    };
  }

  SyncMetaData copyWith({String? key, DateTime? lastSyncedAt}) => SyncMetaData(
        key: key ?? this.key,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      key: data.key.present ? data.key.value : this.key,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('key: $key, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.key == this.key &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> key;
  final Value<DateTime> lastSyncedAt;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required DateTime lastSyncedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        lastSyncedAt = Value(lastSyncedAt);
  static Insertable<SyncMetaData> custom({
    Expression<String>? key,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith(
      {Value<String>? key, Value<DateTime>? lastSyncedAt, Value<int>? rowid}) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HomeFeedItemsTable extends HomeFeedItems
    with TableInfo<$HomeFeedItemsTable, HomeFeedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HomeFeedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sectionMeta =
      const VerificationMeta('section');
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
      'section', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _novelIdMeta =
      const VerificationMeta('novelId');
  @override
  late final GeneratedColumn<String> novelId = GeneratedColumn<String>(
      'novel_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [section, position, novelId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'home_feed_items';
  @override
  VerificationContext validateIntegrity(Insertable<HomeFeedItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('section')) {
      context.handle(_sectionMeta,
          section.isAcceptableOrUnknown(data['section']!, _sectionMeta));
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('novel_id')) {
      context.handle(_novelIdMeta,
          novelId.isAcceptableOrUnknown(data['novel_id']!, _novelIdMeta));
    } else if (isInserting) {
      context.missing(_novelIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {section, position};
  @override
  HomeFeedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HomeFeedItem(
      section: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      novelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}novel_id'])!,
    );
  }

  @override
  $HomeFeedItemsTable createAlias(String alias) {
    return $HomeFeedItemsTable(attachedDatabase, alias);
  }
}

class HomeFeedItem extends DataClass implements Insertable<HomeFeedItem> {
  final String section;
  final int position;
  final String novelId;
  const HomeFeedItem(
      {required this.section, required this.position, required this.novelId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['section'] = Variable<String>(section);
    map['position'] = Variable<int>(position);
    map['novel_id'] = Variable<String>(novelId);
    return map;
  }

  HomeFeedItemsCompanion toCompanion(bool nullToAbsent) {
    return HomeFeedItemsCompanion(
      section: Value(section),
      position: Value(position),
      novelId: Value(novelId),
    );
  }

  factory HomeFeedItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HomeFeedItem(
      section: serializer.fromJson<String>(json['section']),
      position: serializer.fromJson<int>(json['position']),
      novelId: serializer.fromJson<String>(json['novelId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'section': serializer.toJson<String>(section),
      'position': serializer.toJson<int>(position),
      'novelId': serializer.toJson<String>(novelId),
    };
  }

  HomeFeedItem copyWith({String? section, int? position, String? novelId}) =>
      HomeFeedItem(
        section: section ?? this.section,
        position: position ?? this.position,
        novelId: novelId ?? this.novelId,
      );
  HomeFeedItem copyWithCompanion(HomeFeedItemsCompanion data) {
    return HomeFeedItem(
      section: data.section.present ? data.section.value : this.section,
      position: data.position.present ? data.position.value : this.position,
      novelId: data.novelId.present ? data.novelId.value : this.novelId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HomeFeedItem(')
          ..write('section: $section, ')
          ..write('position: $position, ')
          ..write('novelId: $novelId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(section, position, novelId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HomeFeedItem &&
          other.section == this.section &&
          other.position == this.position &&
          other.novelId == this.novelId);
}

class HomeFeedItemsCompanion extends UpdateCompanion<HomeFeedItem> {
  final Value<String> section;
  final Value<int> position;
  final Value<String> novelId;
  final Value<int> rowid;
  const HomeFeedItemsCompanion({
    this.section = const Value.absent(),
    this.position = const Value.absent(),
    this.novelId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HomeFeedItemsCompanion.insert({
    required String section,
    required int position,
    required String novelId,
    this.rowid = const Value.absent(),
  })  : section = Value(section),
        position = Value(position),
        novelId = Value(novelId);
  static Insertable<HomeFeedItem> custom({
    Expression<String>? section,
    Expression<int>? position,
    Expression<String>? novelId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (section != null) 'section': section,
      if (position != null) 'position': position,
      if (novelId != null) 'novel_id': novelId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HomeFeedItemsCompanion copyWith(
      {Value<String>? section,
      Value<int>? position,
      Value<String>? novelId,
      Value<int>? rowid}) {
    return HomeFeedItemsCompanion(
      section: section ?? this.section,
      position: position ?? this.position,
      novelId: novelId ?? this.novelId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (novelId.present) {
      map['novel_id'] = Variable<String>(novelId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HomeFeedItemsCompanion(')
          ..write('section: $section, ')
          ..write('position: $position, ')
          ..write('novelId: $novelId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NovelsTable novels = $NovelsTable(this);
  late final $GenresTable genres = $GenresTable(this);
  late final $NovelGenresTable novelGenres = $NovelGenresTable(this);
  late final $ChaptersMetaTable chaptersMeta = $ChaptersMetaTable(this);
  late final $ChapterContentsTable chapterContents =
      $ChapterContentsTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $HomeFeedItemsTable homeFeedItems = $HomeFeedItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        novels,
        genres,
        novelGenres,
        chaptersMeta,
        chapterContents,
        bookmarks,
        downloads,
        syncMeta,
        homeFeedItems
      ];
}

typedef $$NovelsTableCreateCompanionBuilder = NovelsCompanion Function({
  required String id,
  required String title,
  required String slug,
  required String authorName,
  required String status,
  Value<int> totalChapters,
  Value<String?> originalTitle,
  Value<String?> description,
  Value<String?> coverUrl,
  Value<String?> coverColor,
  Value<int> views,
  Value<double> rating,
  Value<int> ratingCount,
  Value<double?> userRating,
  Value<int> bookmarkCount,
  Value<String?> seriesId,
  Value<String?> genresJson,
  Value<String?> seriesJson,
  Value<String?> latestChapterJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$NovelsTableUpdateCompanionBuilder = NovelsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> slug,
  Value<String> authorName,
  Value<String> status,
  Value<int> totalChapters,
  Value<String?> originalTitle,
  Value<String?> description,
  Value<String?> coverUrl,
  Value<String?> coverColor,
  Value<int> views,
  Value<double> rating,
  Value<int> ratingCount,
  Value<double?> userRating,
  Value<int> bookmarkCount,
  Value<String?> seriesId,
  Value<String?> genresJson,
  Value<String?> seriesJson,
  Value<String?> latestChapterJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$NovelsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $NovelsTable> {
  $$NovelsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get slug => $state.composableBuilder(
      column: $state.table.slug,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get authorName => $state.composableBuilder(
      column: $state.table.authorName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalChapters => $state.composableBuilder(
      column: $state.table.totalChapters,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get originalTitle => $state.composableBuilder(
      column: $state.table.originalTitle,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get coverUrl => $state.composableBuilder(
      column: $state.table.coverUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get coverColor => $state.composableBuilder(
      column: $state.table.coverColor,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get views => $state.composableBuilder(
      column: $state.table.views,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get rating => $state.composableBuilder(
      column: $state.table.rating,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get ratingCount => $state.composableBuilder(
      column: $state.table.ratingCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get userRating => $state.composableBuilder(
      column: $state.table.userRating,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get bookmarkCount => $state.composableBuilder(
      column: $state.table.bookmarkCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get seriesId => $state.composableBuilder(
      column: $state.table.seriesId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get genresJson => $state.composableBuilder(
      column: $state.table.genresJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get seriesJson => $state.composableBuilder(
      column: $state.table.seriesJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get latestChapterJson => $state.composableBuilder(
      column: $state.table.latestChapterJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$NovelsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $NovelsTable> {
  $$NovelsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get slug => $state.composableBuilder(
      column: $state.table.slug,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get authorName => $state.composableBuilder(
      column: $state.table.authorName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalChapters => $state.composableBuilder(
      column: $state.table.totalChapters,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get originalTitle => $state.composableBuilder(
      column: $state.table.originalTitle,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get coverUrl => $state.composableBuilder(
      column: $state.table.coverUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get coverColor => $state.composableBuilder(
      column: $state.table.coverColor,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get views => $state.composableBuilder(
      column: $state.table.views,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get rating => $state.composableBuilder(
      column: $state.table.rating,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get ratingCount => $state.composableBuilder(
      column: $state.table.ratingCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get userRating => $state.composableBuilder(
      column: $state.table.userRating,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get bookmarkCount => $state.composableBuilder(
      column: $state.table.bookmarkCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get seriesId => $state.composableBuilder(
      column: $state.table.seriesId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get genresJson => $state.composableBuilder(
      column: $state.table.genresJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get seriesJson => $state.composableBuilder(
      column: $state.table.seriesJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get latestChapterJson => $state.composableBuilder(
      column: $state.table.latestChapterJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$NovelsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NovelsTable,
    Novel,
    $$NovelsTableFilterComposer,
    $$NovelsTableOrderingComposer,
    $$NovelsTableCreateCompanionBuilder,
    $$NovelsTableUpdateCompanionBuilder,
    (Novel, BaseReferences<_$AppDatabase, $NovelsTable, Novel>),
    Novel,
    PrefetchHooks Function()> {
  $$NovelsTableTableManager(_$AppDatabase db, $NovelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$NovelsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$NovelsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> slug = const Value.absent(),
            Value<String> authorName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> totalChapters = const Value.absent(),
            Value<String?> originalTitle = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> coverColor = const Value.absent(),
            Value<int> views = const Value.absent(),
            Value<double> rating = const Value.absent(),
            Value<int> ratingCount = const Value.absent(),
            Value<double?> userRating = const Value.absent(),
            Value<int> bookmarkCount = const Value.absent(),
            Value<String?> seriesId = const Value.absent(),
            Value<String?> genresJson = const Value.absent(),
            Value<String?> seriesJson = const Value.absent(),
            Value<String?> latestChapterJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NovelsCompanion(
            id: id,
            title: title,
            slug: slug,
            authorName: authorName,
            status: status,
            totalChapters: totalChapters,
            originalTitle: originalTitle,
            description: description,
            coverUrl: coverUrl,
            coverColor: coverColor,
            views: views,
            rating: rating,
            ratingCount: ratingCount,
            userRating: userRating,
            bookmarkCount: bookmarkCount,
            seriesId: seriesId,
            genresJson: genresJson,
            seriesJson: seriesJson,
            latestChapterJson: latestChapterJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String slug,
            required String authorName,
            required String status,
            Value<int> totalChapters = const Value.absent(),
            Value<String?> originalTitle = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> coverColor = const Value.absent(),
            Value<int> views = const Value.absent(),
            Value<double> rating = const Value.absent(),
            Value<int> ratingCount = const Value.absent(),
            Value<double?> userRating = const Value.absent(),
            Value<int> bookmarkCount = const Value.absent(),
            Value<String?> seriesId = const Value.absent(),
            Value<String?> genresJson = const Value.absent(),
            Value<String?> seriesJson = const Value.absent(),
            Value<String?> latestChapterJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NovelsCompanion.insert(
            id: id,
            title: title,
            slug: slug,
            authorName: authorName,
            status: status,
            totalChapters: totalChapters,
            originalTitle: originalTitle,
            description: description,
            coverUrl: coverUrl,
            coverColor: coverColor,
            views: views,
            rating: rating,
            ratingCount: ratingCount,
            userRating: userRating,
            bookmarkCount: bookmarkCount,
            seriesId: seriesId,
            genresJson: genresJson,
            seriesJson: seriesJson,
            latestChapterJson: latestChapterJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NovelsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NovelsTable,
    Novel,
    $$NovelsTableFilterComposer,
    $$NovelsTableOrderingComposer,
    $$NovelsTableCreateCompanionBuilder,
    $$NovelsTableUpdateCompanionBuilder,
    (Novel, BaseReferences<_$AppDatabase, $NovelsTable, Novel>),
    Novel,
    PrefetchHooks Function()>;
typedef $$GenresTableCreateCompanionBuilder = GenresCompanion Function({
  required String id,
  required String name,
  required String slug,
  Value<String?> description,
  Value<String?> icon,
  Value<int> novelCount,
  Value<int> rowid,
});
typedef $$GenresTableUpdateCompanionBuilder = GenresCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> slug,
  Value<String?> description,
  Value<String?> icon,
  Value<int> novelCount,
  Value<int> rowid,
});

class $$GenresTableFilterComposer
    extends FilterComposer<_$AppDatabase, $GenresTable> {
  $$GenresTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get slug => $state.composableBuilder(
      column: $state.table.slug,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get novelCount => $state.composableBuilder(
      column: $state.table.novelCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$GenresTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $GenresTable> {
  $$GenresTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get slug => $state.composableBuilder(
      column: $state.table.slug,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get novelCount => $state.composableBuilder(
      column: $state.table.novelCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$GenresTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GenresTable,
    Genre,
    $$GenresTableFilterComposer,
    $$GenresTableOrderingComposer,
    $$GenresTableCreateCompanionBuilder,
    $$GenresTableUpdateCompanionBuilder,
    (Genre, BaseReferences<_$AppDatabase, $GenresTable, Genre>),
    Genre,
    PrefetchHooks Function()> {
  $$GenresTableTableManager(_$AppDatabase db, $GenresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$GenresTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$GenresTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> slug = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> novelCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GenresCompanion(
            id: id,
            name: name,
            slug: slug,
            description: description,
            icon: icon,
            novelCount: novelCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String slug,
            Value<String?> description = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> novelCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GenresCompanion.insert(
            id: id,
            name: name,
            slug: slug,
            description: description,
            icon: icon,
            novelCount: novelCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GenresTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GenresTable,
    Genre,
    $$GenresTableFilterComposer,
    $$GenresTableOrderingComposer,
    $$GenresTableCreateCompanionBuilder,
    $$GenresTableUpdateCompanionBuilder,
    (Genre, BaseReferences<_$AppDatabase, $GenresTable, Genre>),
    Genre,
    PrefetchHooks Function()>;
typedef $$NovelGenresTableCreateCompanionBuilder = NovelGenresCompanion
    Function({
  required String novelId,
  required String genreId,
  Value<int> rowid,
});
typedef $$NovelGenresTableUpdateCompanionBuilder = NovelGenresCompanion
    Function({
  Value<String> novelId,
  Value<String> genreId,
  Value<int> rowid,
});

class $$NovelGenresTableFilterComposer
    extends FilterComposer<_$AppDatabase, $NovelGenresTable> {
  $$NovelGenresTableFilterComposer(super.$state);
  ColumnFilters<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get genreId => $state.composableBuilder(
      column: $state.table.genreId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$NovelGenresTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $NovelGenresTable> {
  $$NovelGenresTableOrderingComposer(super.$state);
  ColumnOrderings<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get genreId => $state.composableBuilder(
      column: $state.table.genreId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$NovelGenresTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NovelGenresTable,
    NovelGenre,
    $$NovelGenresTableFilterComposer,
    $$NovelGenresTableOrderingComposer,
    $$NovelGenresTableCreateCompanionBuilder,
    $$NovelGenresTableUpdateCompanionBuilder,
    (NovelGenre, BaseReferences<_$AppDatabase, $NovelGenresTable, NovelGenre>),
    NovelGenre,
    PrefetchHooks Function()> {
  $$NovelGenresTableTableManager(_$AppDatabase db, $NovelGenresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$NovelGenresTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$NovelGenresTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> novelId = const Value.absent(),
            Value<String> genreId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NovelGenresCompanion(
            novelId: novelId,
            genreId: genreId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String novelId,
            required String genreId,
            Value<int> rowid = const Value.absent(),
          }) =>
              NovelGenresCompanion.insert(
            novelId: novelId,
            genreId: genreId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NovelGenresTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NovelGenresTable,
    NovelGenre,
    $$NovelGenresTableFilterComposer,
    $$NovelGenresTableOrderingComposer,
    $$NovelGenresTableCreateCompanionBuilder,
    $$NovelGenresTableUpdateCompanionBuilder,
    (NovelGenre, BaseReferences<_$AppDatabase, $NovelGenresTable, NovelGenre>),
    NovelGenre,
    PrefetchHooks Function()>;
typedef $$ChaptersMetaTableCreateCompanionBuilder = ChaptersMetaCompanion
    Function({
  required String id,
  required String novelId,
  required int number,
  required String title,
  Value<int?> volumeNumber,
  Value<String?> volumeTitle,
  Value<int?> volumeChapterNumber,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ChaptersMetaTableUpdateCompanionBuilder = ChaptersMetaCompanion
    Function({
  Value<String> id,
  Value<String> novelId,
  Value<int> number,
  Value<String> title,
  Value<int?> volumeNumber,
  Value<String?> volumeTitle,
  Value<int?> volumeChapterNumber,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ChaptersMetaTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ChaptersMetaTable> {
  $$ChaptersMetaTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get number => $state.composableBuilder(
      column: $state.table.number,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get volumeNumber => $state.composableBuilder(
      column: $state.table.volumeNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get volumeTitle => $state.composableBuilder(
      column: $state.table.volumeTitle,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get volumeChapterNumber => $state.composableBuilder(
      column: $state.table.volumeChapterNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ChaptersMetaTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ChaptersMetaTable> {
  $$ChaptersMetaTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get number => $state.composableBuilder(
      column: $state.table.number,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get volumeNumber => $state.composableBuilder(
      column: $state.table.volumeNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get volumeTitle => $state.composableBuilder(
      column: $state.table.volumeTitle,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get volumeChapterNumber => $state.composableBuilder(
      column: $state.table.volumeChapterNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$ChaptersMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChaptersMetaTable,
    ChaptersMetaData,
    $$ChaptersMetaTableFilterComposer,
    $$ChaptersMetaTableOrderingComposer,
    $$ChaptersMetaTableCreateCompanionBuilder,
    $$ChaptersMetaTableUpdateCompanionBuilder,
    (
      ChaptersMetaData,
      BaseReferences<_$AppDatabase, $ChaptersMetaTable, ChaptersMetaData>
    ),
    ChaptersMetaData,
    PrefetchHooks Function()> {
  $$ChaptersMetaTableTableManager(_$AppDatabase db, $ChaptersMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ChaptersMetaTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ChaptersMetaTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> novelId = const Value.absent(),
            Value<int> number = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int?> volumeNumber = const Value.absent(),
            Value<String?> volumeTitle = const Value.absent(),
            Value<int?> volumeChapterNumber = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChaptersMetaCompanion(
            id: id,
            novelId: novelId,
            number: number,
            title: title,
            volumeNumber: volumeNumber,
            volumeTitle: volumeTitle,
            volumeChapterNumber: volumeChapterNumber,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String novelId,
            required int number,
            required String title,
            Value<int?> volumeNumber = const Value.absent(),
            Value<String?> volumeTitle = const Value.absent(),
            Value<int?> volumeChapterNumber = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChaptersMetaCompanion.insert(
            id: id,
            novelId: novelId,
            number: number,
            title: title,
            volumeNumber: volumeNumber,
            volumeTitle: volumeTitle,
            volumeChapterNumber: volumeChapterNumber,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChaptersMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChaptersMetaTable,
    ChaptersMetaData,
    $$ChaptersMetaTableFilterComposer,
    $$ChaptersMetaTableOrderingComposer,
    $$ChaptersMetaTableCreateCompanionBuilder,
    $$ChaptersMetaTableUpdateCompanionBuilder,
    (
      ChaptersMetaData,
      BaseReferences<_$AppDatabase, $ChaptersMetaTable, ChaptersMetaData>
    ),
    ChaptersMetaData,
    PrefetchHooks Function()>;
typedef $$ChapterContentsTableCreateCompanionBuilder = ChapterContentsCompanion
    Function({
  required String chapterId,
  required String novelId,
  required int number,
  required String title,
  required String content,
  Value<String?> prevChapterId,
  Value<int?> prevChapterNumber,
  Value<String?> nextChapterId,
  Value<int?> nextChapterNumber,
  Value<String?> volumeTitle,
  Value<bool> isDownloaded,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});
typedef $$ChapterContentsTableUpdateCompanionBuilder = ChapterContentsCompanion
    Function({
  Value<String> chapterId,
  Value<String> novelId,
  Value<int> number,
  Value<String> title,
  Value<String> content,
  Value<String?> prevChapterId,
  Value<int?> prevChapterNumber,
  Value<String?> nextChapterId,
  Value<int?> nextChapterNumber,
  Value<String?> volumeTitle,
  Value<bool> isDownloaded,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$ChapterContentsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ChapterContentsTable> {
  $$ChapterContentsTableFilterComposer(super.$state);
  ColumnFilters<String> get chapterId => $state.composableBuilder(
      column: $state.table.chapterId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get number => $state.composableBuilder(
      column: $state.table.number,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get prevChapterId => $state.composableBuilder(
      column: $state.table.prevChapterId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get prevChapterNumber => $state.composableBuilder(
      column: $state.table.prevChapterNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get nextChapterId => $state.composableBuilder(
      column: $state.table.nextChapterId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get nextChapterNumber => $state.composableBuilder(
      column: $state.table.nextChapterNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get volumeTitle => $state.composableBuilder(
      column: $state.table.volumeTitle,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDownloaded => $state.composableBuilder(
      column: $state.table.isDownloaded,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get cachedAt => $state.composableBuilder(
      column: $state.table.cachedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ChapterContentsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ChapterContentsTable> {
  $$ChapterContentsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get chapterId => $state.composableBuilder(
      column: $state.table.chapterId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get number => $state.composableBuilder(
      column: $state.table.number,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get content => $state.composableBuilder(
      column: $state.table.content,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get prevChapterId => $state.composableBuilder(
      column: $state.table.prevChapterId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get prevChapterNumber => $state.composableBuilder(
      column: $state.table.prevChapterNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get nextChapterId => $state.composableBuilder(
      column: $state.table.nextChapterId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get nextChapterNumber => $state.composableBuilder(
      column: $state.table.nextChapterNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get volumeTitle => $state.composableBuilder(
      column: $state.table.volumeTitle,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDownloaded => $state.composableBuilder(
      column: $state.table.isDownloaded,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get cachedAt => $state.composableBuilder(
      column: $state.table.cachedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$ChapterContentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChapterContentsTable,
    ChapterContent,
    $$ChapterContentsTableFilterComposer,
    $$ChapterContentsTableOrderingComposer,
    $$ChapterContentsTableCreateCompanionBuilder,
    $$ChapterContentsTableUpdateCompanionBuilder,
    (
      ChapterContent,
      BaseReferences<_$AppDatabase, $ChapterContentsTable, ChapterContent>
    ),
    ChapterContent,
    PrefetchHooks Function()> {
  $$ChapterContentsTableTableManager(
      _$AppDatabase db, $ChapterContentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ChapterContentsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ChapterContentsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> chapterId = const Value.absent(),
            Value<String> novelId = const Value.absent(),
            Value<int> number = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> prevChapterId = const Value.absent(),
            Value<int?> prevChapterNumber = const Value.absent(),
            Value<String?> nextChapterId = const Value.absent(),
            Value<int?> nextChapterNumber = const Value.absent(),
            Value<String?> volumeTitle = const Value.absent(),
            Value<bool> isDownloaded = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChapterContentsCompanion(
            chapterId: chapterId,
            novelId: novelId,
            number: number,
            title: title,
            content: content,
            prevChapterId: prevChapterId,
            prevChapterNumber: prevChapterNumber,
            nextChapterId: nextChapterId,
            nextChapterNumber: nextChapterNumber,
            volumeTitle: volumeTitle,
            isDownloaded: isDownloaded,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String chapterId,
            required String novelId,
            required int number,
            required String title,
            required String content,
            Value<String?> prevChapterId = const Value.absent(),
            Value<int?> prevChapterNumber = const Value.absent(),
            Value<String?> nextChapterId = const Value.absent(),
            Value<int?> nextChapterNumber = const Value.absent(),
            Value<String?> volumeTitle = const Value.absent(),
            Value<bool> isDownloaded = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChapterContentsCompanion.insert(
            chapterId: chapterId,
            novelId: novelId,
            number: number,
            title: title,
            content: content,
            prevChapterId: prevChapterId,
            prevChapterNumber: prevChapterNumber,
            nextChapterId: nextChapterId,
            nextChapterNumber: nextChapterNumber,
            volumeTitle: volumeTitle,
            isDownloaded: isDownloaded,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChapterContentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChapterContentsTable,
    ChapterContent,
    $$ChapterContentsTableFilterComposer,
    $$ChapterContentsTableOrderingComposer,
    $$ChapterContentsTableCreateCompanionBuilder,
    $$ChapterContentsTableUpdateCompanionBuilder,
    (
      ChapterContent,
      BaseReferences<_$AppDatabase, $ChapterContentsTable, ChapterContent>
    ),
    ChapterContent,
    PrefetchHooks Function()>;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  required String id,
  required String novelId,
  required String type,
  required String shelfStatus,
  Value<String?> lastChapterId,
  Value<int?> lastChapterNumber,
  Value<String> readChaptersJson,
  Value<bool> markedAsRead,
  Value<DateTime> updatedAt,
  Value<bool> pendingSync,
  Value<int> rowid,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<String> id,
  Value<String> novelId,
  Value<String> type,
  Value<String> shelfStatus,
  Value<String?> lastChapterId,
  Value<int?> lastChapterNumber,
  Value<String> readChaptersJson,
  Value<bool> markedAsRead,
  Value<DateTime> updatedAt,
  Value<bool> pendingSync,
  Value<int> rowid,
});

class $$BookmarksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get shelfStatus => $state.composableBuilder(
      column: $state.table.shelfStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastChapterId => $state.composableBuilder(
      column: $state.table.lastChapterId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lastChapterNumber => $state.composableBuilder(
      column: $state.table.lastChapterNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get readChaptersJson => $state.composableBuilder(
      column: $state.table.readChaptersJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get markedAsRead => $state.composableBuilder(
      column: $state.table.markedAsRead,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get pendingSync => $state.composableBuilder(
      column: $state.table.pendingSync,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$BookmarksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get shelfStatus => $state.composableBuilder(
      column: $state.table.shelfStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastChapterId => $state.composableBuilder(
      column: $state.table.lastChapterId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lastChapterNumber => $state.composableBuilder(
      column: $state.table.lastChapterNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get readChaptersJson => $state.composableBuilder(
      column: $state.table.readChaptersJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get markedAsRead => $state.composableBuilder(
      column: $state.table.markedAsRead,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get pendingSync => $state.composableBuilder(
      column: $state.table.pendingSync,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$BookmarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
    Bookmark,
    PrefetchHooks Function()> {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BookmarksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BookmarksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> novelId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> shelfStatus = const Value.absent(),
            Value<String?> lastChapterId = const Value.absent(),
            Value<int?> lastChapterNumber = const Value.absent(),
            Value<String> readChaptersJson = const Value.absent(),
            Value<bool> markedAsRead = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksCompanion(
            id: id,
            novelId: novelId,
            type: type,
            shelfStatus: shelfStatus,
            lastChapterId: lastChapterId,
            lastChapterNumber: lastChapterNumber,
            readChaptersJson: readChaptersJson,
            markedAsRead: markedAsRead,
            updatedAt: updatedAt,
            pendingSync: pendingSync,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String novelId,
            required String type,
            required String shelfStatus,
            Value<String?> lastChapterId = const Value.absent(),
            Value<int?> lastChapterNumber = const Value.absent(),
            Value<String> readChaptersJson = const Value.absent(),
            Value<bool> markedAsRead = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksCompanion.insert(
            id: id,
            novelId: novelId,
            type: type,
            shelfStatus: shelfStatus,
            lastChapterId: lastChapterId,
            lastChapterNumber: lastChapterNumber,
            readChaptersJson: readChaptersJson,
            markedAsRead: markedAsRead,
            updatedAt: updatedAt,
            pendingSync: pendingSync,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
    Bookmark,
    PrefetchHooks Function()>;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String novelId,
  required String status,
  Value<int> totalChapters,
  Value<int> downloadedChapters,
  Value<int> bytesSize,
  Value<String?> errorMessage,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> novelId,
  Value<String> status,
  Value<int> totalChapters,
  Value<int> downloadedChapters,
  Value<int> bytesSize,
  Value<String?> errorMessage,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer(super.$state);
  ColumnFilters<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalChapters => $state.composableBuilder(
      column: $state.table.totalChapters,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get downloadedChapters => $state.composableBuilder(
      column: $state.table.downloadedChapters,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get bytesSize => $state.composableBuilder(
      column: $state.table.bytesSize,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DownloadsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalChapters => $state.composableBuilder(
      column: $state.table.totalChapters,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get downloadedChapters => $state.composableBuilder(
      column: $state.table.downloadedChapters,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get bytesSize => $state.composableBuilder(
      column: $state.table.bytesSize,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$DownloadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
    Download,
    PrefetchHooks Function()> {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DownloadsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DownloadsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> novelId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> totalChapters = const Value.absent(),
            Value<int> downloadedChapters = const Value.absent(),
            Value<int> bytesSize = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion(
            novelId: novelId,
            status: status,
            totalChapters: totalChapters,
            downloadedChapters: downloadedChapters,
            bytesSize: bytesSize,
            errorMessage: errorMessage,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String novelId,
            required String status,
            Value<int> totalChapters = const Value.absent(),
            Value<int> downloadedChapters = const Value.absent(),
            Value<int> bytesSize = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion.insert(
            novelId: novelId,
            status: status,
            totalChapters: totalChapters,
            downloadedChapters: downloadedChapters,
            bytesSize: bytesSize,
            errorMessage: errorMessage,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
    Download,
    PrefetchHooks Function()>;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  required DateTime lastSyncedAt,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<DateTime> lastSyncedAt,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer(super.$state);
  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastSyncedAt => $state.composableBuilder(
      column: $state.table.lastSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncMetaTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer(super.$state);
  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastSyncedAt => $state.composableBuilder(
      column: $state.table.lastSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$SyncMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaData, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>),
    SyncMetaData,
    PrefetchHooks Function()> {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncMetaTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncMetaTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<DateTime> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion(
            key: key,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required DateTime lastSyncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion.insert(
            key: key,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaData, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>),
    SyncMetaData,
    PrefetchHooks Function()>;
typedef $$HomeFeedItemsTableCreateCompanionBuilder = HomeFeedItemsCompanion
    Function({
  required String section,
  required int position,
  required String novelId,
  Value<int> rowid,
});
typedef $$HomeFeedItemsTableUpdateCompanionBuilder = HomeFeedItemsCompanion
    Function({
  Value<String> section,
  Value<int> position,
  Value<String> novelId,
  Value<int> rowid,
});

class $$HomeFeedItemsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $HomeFeedItemsTable> {
  $$HomeFeedItemsTableFilterComposer(super.$state);
  ColumnFilters<String> get section => $state.composableBuilder(
      column: $state.table.section,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get position => $state.composableBuilder(
      column: $state.table.position,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$HomeFeedItemsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $HomeFeedItemsTable> {
  $$HomeFeedItemsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get section => $state.composableBuilder(
      column: $state.table.section,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get position => $state.composableBuilder(
      column: $state.table.position,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get novelId => $state.composableBuilder(
      column: $state.table.novelId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$HomeFeedItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HomeFeedItemsTable,
    HomeFeedItem,
    $$HomeFeedItemsTableFilterComposer,
    $$HomeFeedItemsTableOrderingComposer,
    $$HomeFeedItemsTableCreateCompanionBuilder,
    $$HomeFeedItemsTableUpdateCompanionBuilder,
    (
      HomeFeedItem,
      BaseReferences<_$AppDatabase, $HomeFeedItemsTable, HomeFeedItem>
    ),
    HomeFeedItem,
    PrefetchHooks Function()> {
  $$HomeFeedItemsTableTableManager(_$AppDatabase db, $HomeFeedItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$HomeFeedItemsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$HomeFeedItemsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> section = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<String> novelId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HomeFeedItemsCompanion(
            section: section,
            position: position,
            novelId: novelId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String section,
            required int position,
            required String novelId,
            Value<int> rowid = const Value.absent(),
          }) =>
              HomeFeedItemsCompanion.insert(
            section: section,
            position: position,
            novelId: novelId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HomeFeedItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HomeFeedItemsTable,
    HomeFeedItem,
    $$HomeFeedItemsTableFilterComposer,
    $$HomeFeedItemsTableOrderingComposer,
    $$HomeFeedItemsTableCreateCompanionBuilder,
    $$HomeFeedItemsTableUpdateCompanionBuilder,
    (
      HomeFeedItem,
      BaseReferences<_$AppDatabase, $HomeFeedItemsTable, HomeFeedItem>
    ),
    HomeFeedItem,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NovelsTableTableManager get novels =>
      $$NovelsTableTableManager(_db, _db.novels);
  $$GenresTableTableManager get genres =>
      $$GenresTableTableManager(_db, _db.genres);
  $$NovelGenresTableTableManager get novelGenres =>
      $$NovelGenresTableTableManager(_db, _db.novelGenres);
  $$ChaptersMetaTableTableManager get chaptersMeta =>
      $$ChaptersMetaTableTableManager(_db, _db.chaptersMeta);
  $$ChapterContentsTableTableManager get chapterContents =>
      $$ChapterContentsTableTableManager(_db, _db.chapterContents);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$HomeFeedItemsTableTableManager get homeFeedItems =>
      $$HomeFeedItemsTableTableManager(_db, _db.homeFeedItems);
}
