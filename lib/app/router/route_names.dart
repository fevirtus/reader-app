class RouteNames {
  RouteNames._();

  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const search = '/search';
  static const genres = '/genres';
  static const bookshelf = '/bookshelf';
  static const profile = '/profile';
  static const settings = '/settings';

  // Path-param based routes
  static const novelDetailPath = '/novel/:id';
  static const readerPath = '/reader/:chapterId';
  static const commentsPath = '/comments/:novelId';

  // Navigation helpers
  static String novelDetail(String id) => '/novel/$id';
  static String readerChapter(String chapterId) => '/reader/$chapterId';
  static String commentsFor(String novelId, {String? chapterId}) {
    final base = '/comments/$novelId';
    return chapterId != null ? '$base?chapterId=$chapterId' : base;
  }
}
