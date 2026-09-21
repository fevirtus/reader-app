import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Tiêu đề mục có kèm liên kết "Xem thêm" tuỳ chọn — dùng ở Trang chủ và
/// những nơi có danh sách con cần dẫn sang màn xem đầy đủ.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onMore});

  final String title;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, AppSpacing.lg, 20, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (onMore != null)
            InkWell(
              onTap: onMore,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Tất cả',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
