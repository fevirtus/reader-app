import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith(RouteNames.search)) return 1;
    if (location.startsWith(RouteNames.bookshelf)) return 2;
    if (location.startsWith(RouteNames.genres)) return 3;
    if (location.startsWith(RouteNames.profile)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.home);
            case 1:
              context.go(RouteNames.search);
            case 2:
              context.go(RouteNames.bookshelf);
            case 3:
              context.go(RouteNames.genres);
            case 4:
              context.go(RouteNames.profile);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Tim kiem'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), label: 'Tu sach'),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: 'The loai'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Tai khoan'),
        ],
      ),
    );
  }
}
