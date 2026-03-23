import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/bookshelf/presentation/bookshelf_screen.dart';
import '../../features/comments/presentation/comments_screen.dart';
import '../../features/genres/presentation/genres_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/novel/presentation/novel_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RouteNames.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: RouteNames.genres,
            builder: (context, state) => const GenresScreen(),
          ),
          GoRoute(
            path: RouteNames.bookshelf,
            builder: (context, state) => const BookshelfScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.novelDetail,
        builder: (_, state) => NovelDetailScreen(
          novelId: state.uri.queryParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.reader,
        builder: (_, state) => ReaderScreen(
          chapterId: state.uri.queryParameters['chapterId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.comments,
        builder: (_, state) => CommentsScreen(
          novelId: state.uri.queryParameters['novelId'] ?? '',
          chapterId: state.uri.queryParameters['chapterId'],
        ),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
