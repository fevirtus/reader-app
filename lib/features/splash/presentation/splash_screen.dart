import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/storage/local_store.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isRestorableRoute(String path) {
    if (path.isEmpty || path == RouteNames.splash) return false;
    if (path.contains('|')) {
      final parts = path.split('|');
      return parts.length == 2 && parts.every(_isRestorableRoute);
    }
    final checkPath = path;
    return checkPath == RouteNames.home ||
        checkPath == RouteNames.login ||
        checkPath == RouteNames.search ||
        checkPath.startsWith('${RouteNames.search}?') ||
        checkPath == RouteNames.genres ||
        checkPath == RouteNames.bookshelf ||
        checkPath == RouteNames.profile ||
        checkPath == RouteNames.settings ||
        checkPath.startsWith('/novel/') ||
        checkPath.startsWith('/reader/');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      String? lastPath;
      try {
        lastPath = await ref.read(localStoreProvider).loadLastRoutePath();
      } catch (_) {
        // A failed preference read must not leave the app on the splash screen.
      }
      if (!mounted) return;
      if (lastPath != null && _isRestorableRoute(lastPath)) {
        if (lastPath.contains('|')) {
          // Composite "parentPath|deepPath" e.g. "/novel/123|/reader/abc"
          // Restore full stack: Home → Novel Detail → Reader
          final sep = lastPath.indexOf('|');
          final parentPath = lastPath.substring(0, sep);
          final deepPath = lastPath.substring(sep + 1);
          context.go(RouteNames.home);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.push(parentPath);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.push(deepPath);
            });
          });
        } else {
          // Single deep route (novel, comments) outside ShellRoute: push on Home
          final isDeepRoute =
              lastPath.startsWith('/reader/') || lastPath.startsWith('/novel/');
          if (isDeepRoute) {
            context.go(RouteNames.home);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.push(lastPath!);
            });
          } else {
            context.go(lastPath);
          }
        }
        return;
      }
      context.go(RouteNames.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 48),
            SizedBox(height: 12),
            Text('Reader App'),
          ],
        ),
      ),
    );
  }
}
