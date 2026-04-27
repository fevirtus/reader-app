import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session_expiry_notifier.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/local_store.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/reader/tts/tts_service.dart';
import 'router/route_names.dart';
import 'router/app_router.dart';

class ReaderApp extends ConsumerStatefulWidget {
  const ReaderApp({super.key});

  @override
  ConsumerState<ReaderApp> createState() => _ReaderAppState();
}

class _ReaderAppState extends ConsumerState<ReaderApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  ProviderSubscription<int>? _sessionExpirySub;
  late final GoRouter _router;
  String? _previousPath;

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
    _router = ref.read(appRouterProvider);
    _router.routerDelegate.addListener(_persistRouteForRestore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureMandatoryTtsRequirements();
    });

    _sessionExpirySub = ref.listenManual<int>(
      sessionExpiryProvider,
      (previous, next) async {
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
              content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
            ),
          );
      },
    );
  }

  Future<void> _ensureMandatoryTtsRequirements() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android || !mounted) {
      return;
    }

    final notifier = ref.read(ttsProvider.notifier);
    await notifier.setBackgroundModeEnabled(true);
    await notifier.ensureBatteryOptimizationIgnored();
    if (!mounted) return;

    while (mounted && !ref.read(ttsProvider).batteryOptimizationIgnored) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Yeu cau bat buoc cho TTS'),
            content: const Text(
              'Can bat Chay nen va Loai tru toi uu pin de TTS khong bi ngat dot ngot.',
            ),
            actions: [
              FilledButton(
                onPressed: () async {
                  await notifier.setBackgroundModeEnabled(true);
                  await notifier.ensureBatteryOptimizationIgnored();
                  if (!context.mounted) return;
                  if (ref.read(ttsProvider).batteryOptimizationIgnored) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Bat ngay'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
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
    );
  }
}
