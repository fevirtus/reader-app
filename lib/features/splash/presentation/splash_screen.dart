import 'dart:async';

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
  Timer? _redirectTimer;

  bool _isRestorableRoute(String path) {
    if (path.isEmpty || path == RouteNames.splash) return false;
    return path == RouteNames.home ||
        path == RouteNames.login ||
        path == RouteNames.search ||
        path.startsWith('${RouteNames.search}?') ||
        path == RouteNames.genres ||
        path == RouteNames.bookshelf ||
        path == RouteNames.profile ||
        path == RouteNames.settings ||
        path.startsWith('/novel/') ||
        path.startsWith('/reader/') ||
        path.startsWith('/comments/');
  }

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final lastPath = await ref.read(localStoreProvider).loadLastRoutePath();
      if (!mounted) return;
      if (lastPath != null && _isRestorableRoute(lastPath)) {
        context.go(lastPath);
        return;
      }
      context.go(RouteNames.home);
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
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
