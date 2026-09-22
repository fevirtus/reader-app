import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_app/core/repositories/downloads_repository.dart';
import 'package:reader_app/core/storage/database/app_database.dart';
import 'package:reader_app/core/theme/app_theme.dart';
import 'package:reader_app/features/downloads/presentation/downloads_tab.dart';
import 'package:reader_app/features/downloads/providers/downloads_provider.dart';
import 'package:reader_app/features/genres/providers/genres_provider.dart';
import 'package:reader_app/features/novel/providers/novels_provider.dart';
import 'package:reader_app/features/search/presentation/search_screen.dart';
import 'widget_test.dart' show novel;
import 'package:reader_app/shared/widgets/empty_state.dart';

class FixedBrowse extends NovelsNotifier {
  FixedBrowse(super.ref);
  int calls = 0;
  @override
  Future<void> updateParams(BrowseParams params) async {
    calls++;
    state = const AsyncData(
      BrowseResult(
        items: [novel],
        totalCount: 1,
        totalPages: 1,
        currentPage: 1,
      ),
    );
  }
}

void main() {
  testWidgets('error state fits the remaining space above a keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: const SizedBox(
              height: 140,
              width: 320,
              child: EmptyState(
                icon: Icons.cloud_off,
                title: 'Không thể tải kết quả',
                subtitle: 'Kiểm tra kết nối mạng rồi thử lại nhé.',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'search tolerates invalid sort, large text and submit during debounce ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        late FixedBrowse browse;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              novelsProvider.overrideWith((ref) => browse = FixedBrowse(ref)),
              genresListProvider.overrideWith((ref) => Stream.value([])),
              genresSyncProvider.overrideWith((ref) => GenresSyncNotifier(ref)),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.6)),
                child: child!,
              ),
              home: const SearchScreen(initialSort: 'not-a-sort'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(browse.calls, 1);
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField), 'abc');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump(const Duration(milliseconds: 600));
        expect(browse.calls, 2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'download controls fit large text and deletion requires confirmation ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              downloadsListProvider.overrideWith(
                (ref) => Stream.value([
                  DownloadWithNovel(
                    novel: novel,
                    download: Download(
                      novelId: novel.id,
                      status: 'failed',
                      totalChapters: 120,
                      downloadedChapters: 10,
                      bytesSize: 1024,
                      updatedAt: DateTime(2026),
                    ),
                  ),
                ]),
              ),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.6)),
                child: child!,
              ),
              home: const Scaffold(body: DownloadsTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Mở truyện'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Tuỳ chọn bản tải'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xoá bản tải'));
        await tester.pumpAndSettle();
        expect(find.text('Xoá bản tải xuống?'), findsOneWidget);
        await tester.tap(find.text('Giữ lại'));
        await tester.pumpAndSettle();
        expect(find.text('Mở truyện'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('downloads loading is not shown as an empty library', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadsListProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(home: Scaffold(body: DownloadsTab())),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Chưa tải truyện nào để đọc ngoại tuyến'), findsNothing);
  });
}
