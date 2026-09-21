import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_names.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final path = GoRouterState.of(context).uri.path;
    final index = path.startsWith(RouteNames.bookshelf)
        ? 1
        : path.startsWith(RouteNames.genres)
        ? 2
        : path.startsWith(RouteNames.profile)
        ? 3
        : 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          height: 72,
          elevation: 0,
          backgroundColor: cs.surface,
          indicatorColor: cs.primary.withAlpha(25),
          onDestinationSelected: (i) => context.go(
            [
              RouteNames.home,
              RouteNames.bookshelf,
              RouteNames.genres,
              RouteNames.profile,
            ][i],
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Khám phá',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmarks_outlined),
              selectedIcon: Icon(Icons.bookmarks_rounded),
              label: 'Tủ sách',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Thể loại',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
