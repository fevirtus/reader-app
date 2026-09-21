import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';

class MainAppHeader extends StatelessWidget {
  const MainAppHeader({
    super.key,
    this.title = 'Đăng truyện',
    this.showSearch = true,
    this.showGenresShortcut = true,
    this.bottom,
  });

  final String title;
  final bool showSearch;
  final bool showGenresShortcut;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(245),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(90)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.go(RouteNames.home),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Image.asset(
                        'assets/app_icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.menu_book_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Virtus's Reader",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (showSearch)
                  IconButton(
                    tooltip: 'Tìm kiếm',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.go(RouteNames.search),
                    icon: const Icon(Icons.search_rounded),
                    color: colorScheme.onSurface,
                  ),
              ],
            ),
            if (bottom != null) ...[
              const SizedBox(height: 12),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}





