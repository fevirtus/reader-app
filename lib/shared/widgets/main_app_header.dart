import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_names.dart';

class MainAppHeader extends StatelessWidget {
  const MainAppHeader({
    super.key,
    this.title = 'Khám phá',
    this.subtitle,
    this.showSearch = true,
    this.showGenresShortcut = true,
    this.bottom,
  });
  final String title;
  final String? subtitle;
  final bool showSearch;
  final bool showGenresShortcut;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VIRTUS READER',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showSearch)
                    IconButton.filledTonal(
                      tooltip: 'Tìm truyện',
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surface,
                        foregroundColor: cs.onSurface,
                        minimumSize: const Size(48, 48),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      onPressed: () => context.go(RouteNames.search),
                      icon: const Icon(Icons.search_rounded),
                    ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              if (bottom != null) ...[const SizedBox(height: 18), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}
