import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reader_app/features/settings/presentation/settings_screen.dart';
import 'package:reader_app/core/models/novel_model.dart';
import 'package:reader_app/core/theme/app_theme.dart';
import 'package:reader_app/features/home/presentation/home_screen.dart';
import 'package:reader_app/features/home/providers/home_provider.dart';
import 'package:reader_app/features/genres/presentation/genres_screen.dart';
import 'package:reader_app/features/genres/providers/genres_provider.dart';
import 'package:reader_app/shared/widgets/section_header.dart';

const novel = NovelModel(
  id: '1',
  title: 'Một câu chuyện rất dài để kiểm tra bố cục trên điện thoại',
  slug: 'truyen',
  authorName: 'Tác giả',
  status: 'Hoàn thành',
  totalChapters: 120,
);

void main() {
  testWidgets('Home shortcuts navigate to the requested sorting', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (_, state) =>
              Scaffold(body: Text('sort=${state.uri.queryParameters['sort']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataProvider.overrideWithValue(
            const HomeData(
              hot: [novel],
              latest: [novel],
              topRated: [],
              topViews: [],
            ),
          ),
          homeSyncProvider.overrideWith((ref) => HomeSyncNotifier(ref)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đọc nhiều'));
    await tester.pumpAndSettle();
    expect(find.text('sort=popular'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Genre search filters locally and reports no results', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          genresListProvider.overrideWith(
            (ref) => Stream.value(const [
              GenreModel(
                id: '1',
                name: 'Tiên hiệp',
                slug: 'tien-hiep',
                novelCount: 5,
              ),
              GenreModel(
                id: '2',
                name: 'Đô thị',
                slug: 'do-thi',
                novelCount: 2,
              ),
            ]),
          ),
          genresSyncProvider.overrideWith((ref) => GenresSyncNotifier(ref)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GenresScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tiên');
    await tester.pump();
    expect(find.text('Tiên hiệp'), findsOneWidget);
    expect(find.text('Đô thị'), findsNothing);
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('Không có thể loại phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'Home supports narrow layout and larger text (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeDataProvider.overrideWithValue(
                const HomeData(
                  hot: [novel],
                  latest: [novel],
                  topRated: [novel],
                  topViews: [novel],
                ),
              ),
              homeSyncProvider.overrideWith((ref) => HomeSyncNotifier(ref)),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.4)),
                child: child!,
              ),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(SectionHeader), findsWidgets);
      },
    );
  }
  testWidgets(
    'Reading settings preview follows font selection and reset on a small screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.4)),
              child: child!,
            ),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đơn cách'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đơn cách'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 1500));
      await tester.pumpAndSettle();
      final preview = find.textContaining('Khép lại những vội vã');
      expect(tester.widget<Text>(preview).style?.fontFamily, 'Courier');
      await tester.tap(find.text('Mặc định'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(preview).style?.fontFamily, 'Georgia');
      expect(tester.takeException(), isNull);
    },
  );
}
