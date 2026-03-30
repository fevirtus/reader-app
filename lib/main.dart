import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/logging/app_provider_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[APP][FLUTTER_ERROR] ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[APP][PLATFORM_ERROR] $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  runZonedGuarded(
    () {
      runApp(
        const ProviderScope(
          observers: [AppProviderObserver()],
          child: ReaderApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('[APP][UNCAUGHT_ASYNC] $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}
