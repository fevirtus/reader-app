import '../core/connectivity/connectivity_service.dart';
import '../core/sync/user_sync.dart';
import '../features/bookshelf/providers/bookshelf_provider.dart';
import '../features/home/providers/home_provider.dart';
import '../features/genres/providers/genres_provider.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session_expiry_notifier.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/local_store.dart';
import '../features/auth/providers/auth_provider.dart';
import '../shared/widgets/offline_banner.dart';
import 'router/route_names.dart';
import 'router/app_router.dart';

class ReaderApp extends ConsumerStatefulWidget {
  const ReaderApp({super.key});

  @override
  ConsumerState<ReaderApp> createState() => _ReaderAppState();
}

class _ReaderAppState extends ConsumerState<ReaderApp>
    with WidgetsBindingObserver {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  ProviderSubscription<int>? _sessionExpirySub;
  late final GoRouter _router;
  String? _previousPath;
  Timer? _syncTimer;
  ProviderSubscription<AsyncValue<bool>>? _networkSub;
  ProviderSubscription<AuthState>? _authSub;
  bool _syncing = false;

  Future<void> _syncOnline({bool refresh = false}) async {
    if (_syncing || !mounted) return;
    _syncing = true;
    try {
      if (!await ref.read(connectivityServiceProvider).checkIsOnline()) return;
      if (!mounted) return;
      await ref.read(authProvider.notifier).refreshSession();
      if (!mounted) return;
      await ref.read(userSyncProvider).flush();
      if (!mounted) return;
      await ref.read(bookshelfProvider.notifier).fetch();
      if (refresh && mounted) {
        await Future.wait([
          ref.read(homeSyncProvider.notifier).refresh(),
          ref.read(genresSyncProvider.notifier).refresh(),
        ]);
      }
    } catch (_) {
      // All unacknowledged edits remain in the outbox for the next retry.
    } finally {
      _syncing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncOnline(refresh: true));
    }
  }

  void _persistRouteForRestore() {
    if (!mounted) return;
    final uri = _router.state.uri;
    final fullPath = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    if (fullPath == RouteNames.splash) return;

    // When navigating into reader from a novel page, save "novelPath|readerPath"
    // so the splash screen can reconstruct the full back stack on restore.
    final String pathToSave;
    if (fullPath.startsWith('/reader/') &&
        _previousPath != null &&
        _previousPath!.startsWith('/novel/')) {
      pathToSave = '$_previousPath|$fullPath';
    } else {
      pathToSave = fullPath;
    }
    _previousPath = fullPath;

    unawaited(ref.read(localStoreProvider).saveLastRoutePath(pathToSave));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _networkSub = ref.listenManual(isOnlineProvider, (previous, next) {
      if (next.valueOrNull == true && previous?.valueOrNull != true) {
        unawaited(_syncOnline(refresh: true));
      }
    });
    _authSub = ref.listenManual(authProvider, (_, next) {
      ref.read(syncErrorProvider.notifier).state = null;
      if (next is AuthAuthenticated) unawaited(_syncOnline());
    });
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_syncOnline()),
    );
    _router = ref.read(appRouterProvider);
    _router.routerDelegate.addListener(_persistRouteForRestore);

    _sessionExpirySub = ref.listenManual<int>(sessionExpiryProvider, (
      previous,
      next,
    ) async {
      if (previous == null || next == previous) return;

      await ref.read(authProvider.notifier).handleSessionExpired();

      if (!mounted) return;
      final router = ref.read(appRouterProvider);
      if (router.state.uri.path != RouteNames.login) {
        router.go(RouteNames.login);
      }

      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            ),
          ),
        );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _networkSub?.close();
    _authSub?.close();
    _router.routerDelegate.removeListener(_persistRouteForRestore);
    _sessionExpirySub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Reader App',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
