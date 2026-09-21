import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/reading_settings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/settings_controls.dart';
import '../../reader/providers/reader_provider.dart';

/// Cùng dùng [readingSettingsProvider] với bảng tuỳ chỉnh nhanh trong Reader —
/// đổi ở đâu cũng đồng bộ ngay, không còn 2 nguồn cài đặt lệch nhau.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _backgroundColorChoices = [
    Color(0xFFFFFEF8),
    Color(0xFFF6EAD7),
    Color(0xFF101418),
    Color(0xFFF3F7FF),
    Color(0xFFF6FFF5),
  ];

  static const _textColorChoices = [
    Color(0xFF111111),
    Color(0xFF2C1E12),
    Color(0xFFE6EAF2),
    Color(0xFF1F2A44),
    Color(0xFF0F5132),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);
    final notifier = ref.read(readingSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> update(ReadingSettings next) => notifier.update(next);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt đọc'),
        actions: [
          TextButton(
            onPressed: () => update(const ReadingSettings()),
            child: const Text('Mặc định'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Điều chỉnh cho mắt bạn thoải mái nhất.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SettingsSection(
            title: 'Xem trước',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Color(settings.backgroundColorValue),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                'Khép lại những vội vã, mở ra một trang sách. Một câu chuyện mới đang chờ bạn phía trước.',
                textAlign: settings.textAlign == 'center'
                    ? TextAlign.center
                    : settings.textAlign == 'justify'
                    ? TextAlign.justify
                    : TextAlign.left,
                style: TextStyle(
                  color: Color(settings.textColorValue),
                  fontSize: settings.fontSize,
                  height: settings.lineHeight,
                  letterSpacing: settings.letterSpacing,
                  fontFamily: settings.fontFamily == 'serif'
                      ? 'Georgia'
                      : settings.fontFamily == 'mono'
                      ? 'Courier'
                      : null,
                ),
              ),
            ),
          ),
          SettingsSection(
            title: 'Kiểu chữ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final choice in const [
                      ('serif', 'Có chân'),
                      ('sans', 'Không chân'),
                      ('mono', 'Đơn cách'),
                    ])
                      ChoiceChip(
                        label: Text(choice.$2),
                        selected: settings.fontFamily == choice.$1,
                        onSelected: (_) =>
                            update(settings.copyWith(fontFamily: choice.$1)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledSlider(
                  label: 'Cỡ chữ',
                  valueLabel: settings.fontSize.toStringAsFixed(0),
                  min: 12,
                  max: 32,
                  divisions: 10,
                  value: settings.fontSize,
                  onChanged: (v) => update(settings.copyWith(fontSize: v)),
                ),
                LabeledSlider(
                  label: 'Giãn dòng',
                  valueLabel: settings.lineHeight.toStringAsFixed(1),
                  min: 1.2,
                  max: 3.0,
                  divisions: 9,
                  value: settings.lineHeight,
                  onChanged: (v) => update(settings.copyWith(lineHeight: v)),
                ),
                LabeledSlider(
                  label: 'Khoảng cách chữ',
                  valueLabel: settings.letterSpacing.toStringAsFixed(1),
                  min: 0,
                  max: 4,
                  divisions: 8,
                  value: settings.letterSpacing,
                  onChanged: (v) => update(settings.copyWith(letterSpacing: v)),
                ),
              ],
            ),
          ),
          SettingsSection(
            title: 'Giao diện đọc',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Màu nền', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _backgroundColorChoices
                      .map(
                        (color) => ColorOptionChip(
                          color: color,
                          selected:
                              settings.backgroundColorValue == color.toARGB32(),
                          onTap: () => update(
                            settings.copyWith(
                              backgroundColorValue: color.toARGB32(),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Màu chữ', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _textColorChoices
                      .map(
                        (color) => ColorOptionChip(
                          color: color,
                          selected: settings.textColorValue == color.toARGB32(),
                          onTap: () => update(
                            settings.copyWith(textColorValue: color.toARGB32()),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          SettingsSection(
            title: 'Bố cục trang',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Canh chữ', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'left', label: Text('Trái')),
                    ButtonSegment(value: 'justify', label: Text('Đều')),
                    ButtonSegment(value: 'center', label: Text('Giữa')),
                  ],
                  selected: {settings.textAlign},
                  onSelectionChanged: (s) =>
                      update(settings.copyWith(textAlign: s.first)),
                ),
                const SizedBox(height: AppSpacing.md),
                LabeledSlider(
                  label: 'Lề ngang',
                  valueLabel: settings.horizontalPadding.toStringAsFixed(0),
                  min: 12,
                  max: 36,
                  divisions: 8,
                  value: settings.horizontalPadding,
                  onChanged: (v) =>
                      update(settings.copyWith(horizontalPadding: v)),
                ),
                LabeledSlider(
                  label: 'Khoảng cách đoạn',
                  valueLabel: settings.paragraphSpacing.toStringAsFixed(0),
                  min: 8,
                  max: 36,
                  divisions: 7,
                  value: settings.paragraphSpacing,
                  onChanged: (v) =>
                      update(settings.copyWith(paragraphSpacing: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
