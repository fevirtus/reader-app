import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Dải thông báo mỏng, cố định ở đỉnh app, hiện khi thiết bị mất mạng.
/// Đặt ở `MaterialApp.router(builder: ...)` để phủ mọi màn hình, kể cả
/// những route nằm ngoài [AppShell] (novel detail, reader...).
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    // Mặc định coi là online khi chưa xác định được (tránh nháy banner lúc khởi động).
    final isOffline = isOnlineAsync.valueOrNull == false;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: isOffline ? const _OfflineBar() : const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final warning = isDark ? AppColors.darkWarning : AppColors.lightWarning;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 15, color: warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Đang ngoại tuyến — hiển thị dữ liệu đã lưu',
                style: theme.textTheme.labelMedium?.copyWith(color: warning),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
