import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  String _tabForLocation(String location) {
    if (location.startsWith(RouteNames.bookshelf)) return RouteNames.bookshelf;
    if (location.startsWith(RouteNames.genres)) return RouteNames.genres;
    if (location.startsWith(RouteNames.profile)) return RouteNames.profile;
    return RouteNames.home;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final location = GoRouterState.of(context).uri.path;
    final selectedTab = _tabForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                _ShellNavItem(
                  icon: Icons.home_rounded,
                  label: 'Trang chủ',
                  selected: selectedTab == RouteNames.home,
                  onTap: () => context.go(RouteNames.home),
                ),
                _ShellNavItem(
                  icon: Icons.layers_rounded,
                  label: 'Tủ sách',
                  selected: selectedTab == RouteNames.bookshelf,
                  onTap: () => context.go(RouteNames.bookshelf),
                ),
                _ShellNavItem(
                  icon: Icons.category_rounded,
                  label: 'Thể loại',
                  selected: selectedTab == RouteNames.genres,
                  onTap: () => context.go(RouteNames.genres),
                ),
                _ShellNavItem(
                  icon: Icons.person_rounded,
                  label: 'Tài khoản',
                  selected: selectedTab == RouteNames.profile,
                  onTap: () => context.go(RouteNames.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = const Color(0xFF14B8A6);
    final inactiveColor = colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected ? activeColor.withAlpha(28) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? const Color(0xFFF7B500) : inactiveColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
