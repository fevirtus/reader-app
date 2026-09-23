import 'dart:async';
import 'dart:ui';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/logging/app_provider_observer.dart';
import 'features/audiobook/audio_book_migration.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      unawaited(
        removeRetiredAudioDownloads().catchError((Object error) {
          debugPrint('Audio book cleanup will retry on next launch: $error');
        }),
      );
      await JustAudioBackground.init(
        androidNotificationChannelId: "reader.audio_book",
        androidNotificationChannelName: "Audio book",
        androidNotificationOngoing: true,
      );

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
