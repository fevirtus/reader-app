import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sleep_timer.dart';

String sleepTimeLabel(Duration remaining) {
  final seconds = (remaining.inMilliseconds / 1000).ceil();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class SleepTimerButton extends ConsumerWidget {
  const SleepTimerButton({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    final remaining = timer.remaining;
    final label = remaining == null ? 'Hẹn giờ tắt' : sleepTimeLabel(remaining);
    void open() {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        builder: (_) => const _SleepTimerSheet(),
      );
    }

    if (compact) {
      return IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: remaining == null ? label : 'Hẹn giờ tắt · $label',
        onPressed: open,
        icon: remaining == null
            ? const Icon(Icons.bedtime_outlined, size: 20)
            : Text(
                '${(remaining.inSeconds / 60).ceil()}′',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
      );
    }
    return TextButton.icon(
      onPressed: open,
      icon: Icon(
        remaining == null ? Icons.bedtime_outlined : Icons.bedtime,
        size: 18,
      ),
      label: Text(label),
    );
  }
}

class _SleepTimerSheet extends ConsumerStatefulWidget {
  const _SleepTimerSheet();
  @override
  ConsumerState<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<_SleepTimerSheet> {
  bool _busy = false;
  String? _error;
  Future<void> choose(int? minutes) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(sleepTimerProvider)
          .set(minutes == null ? null : Duration(minutes: minutes));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Chưa đặt được hẹn giờ. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(sleepTimerProvider);
    final remaining = timer.remaining;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hẹn giờ tắt', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Áp dụng cho TTS và Audio book. Hết giờ sẽ tạm dừng và giữ vị trí nghe.',
              style: theme.textTheme.bodyMedium,
            ),
            if (remaining != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.bedtime,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Còn ${sleepTimeLabel(remaining)}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => choose(null),
                      child: const Text('Huỷ hẹn giờ'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [10, 15, 30, 45, 60, 90]
                  .map(
                    (minutes) => OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(76, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onPressed: _busy ? null : () => choose(minutes),
                      child: Text('$minutes phút'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Thời gian vẫn đếm khi tạm dừng hoặc chuyển chương.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_error != null || timer.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error ?? timer.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
