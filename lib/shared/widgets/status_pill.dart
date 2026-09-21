import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum StatusPillTone { success, neutral, warning }

/// Huy hiệu trạng thái nhỏ (vd: "Hoàn thành", "Đang ra") — nền mờ nhạt +
/// chữ cùng tông, tránh dùng màu nhấn chính của app (accent chỉ dành cho
/// hành động/lựa chọn, không dùng để gắn nhãn trạng thái).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = StatusPillTone.neutral});

  final String label;
  final StatusPillTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (tone) {
      StatusPillTone.success => isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
      StatusPillTone.warning => isDark ? AppColors.darkWarning : AppColors.lightWarning,
      StatusPillTone.neutral => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, letterSpacing: 0),
      ),
    );
  }
}
