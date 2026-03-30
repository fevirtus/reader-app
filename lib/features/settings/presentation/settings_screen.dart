import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final isAuth = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt đọc')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Cỡ chữ: ${settings.fontSize.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleSmall),
            Slider(
              min: 12,
              max: 28,
              divisions: 8,
              value: settings.fontSize,
              onChanged: (v) => ref
                  .read(userSettingsProvider.notifier)
                  .updateSettings(settings.copyWith(fontSize: v)),
            ),
            const SizedBox(height: 8),
            Text('Khoảng cách dòng: ${settings.lineHeight.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.titleSmall),
            Slider(
              min: 1.2,
              max: 3.0,
              divisions: 9,
              value: settings.lineHeight,
              onChanged: (v) => ref
                  .read(userSettingsProvider.notifier)
                  .updateSettings(settings.copyWith(lineHeight: v)),
            ),
            const SizedBox(height: 8),
            Text('Khoảng cách chữ: ${settings.letterSpacing.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.titleSmall),
            Slider(
              min: 0,
              max: 4,
              divisions: 8,
              value: settings.letterSpacing,
              onChanged: (v) => ref
                  .read(userSettingsProvider.notifier)
                  .updateSettings(settings.copyWith(letterSpacing: v)),
            ),
            const SizedBox(height: 8),
            Text('Font chữ', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'serif', label: Text('Serif')),
                ButtonSegment(value: 'sans', label: Text('Sans-serif')),
                ButtonSegment(value: 'mono', label: Text('Mono')),
              ],
              selected: {settings.fontFamily},
              onSelectionChanged: (s) => ref
                  .read(userSettingsProvider.notifier)
                  .updateSettings(settings.copyWith(fontFamily: s.first)),
            ),
            const Divider(height: 40),
            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Đây là đoạn văn mẫu để xem trước cài đặt hiển thị chữ của bạn.',
                style: TextStyle(
                  fontSize: settings.fontSize,
                  height: settings.lineHeight,
                  letterSpacing: settings.letterSpacing,
                  fontFamily: settings.fontFamily == 'serif' ? 'Georgia' : null,
                ),
              ),
            ),
            const Divider(height: 40),
            if (isAuth)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Đăng xuất',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) context.go(RouteNames.home);
                },
              ),
          ],
        ),
      ),
    );
  }
}
