import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_expiry_notifier.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
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
