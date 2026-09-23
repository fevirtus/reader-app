import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_names.dart';
import 'audio_book_controller.dart';

/// Full-screen listening uses the same background player as the chapter library.
class AudioBookPlayerScreen extends ConsumerWidget {
  const AudioBookPlayerScreen({super.key});
  String clock(Duration value) {
    final seconds = value.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(audioBookControllerProvider);
    final chapter = c.chapter;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đang nghe'),
        actions: [
          IconButton(
            tooltip: 'Danh sách chương',
            icon: const Icon(Icons.queue_music),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: chapter == null
          ? const Center(child: Text('Chọn một chương để bắt đầu nghe.'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          width: 200,
                          height: 200,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: c.edition?['coverUrl'] != null
                              ? Image.network(
                                  c.edition!['coverUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stack) => Icon(
                                    Icons.headphones,
                                    size: 80,
                                    color: colors.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.headphones,
                                  size: 80,
                                  color: colors.primary,
                                ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          c.edition?['title'] ?? 'Audio book',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chương ${chapter['number']}',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          chapter['title'] ?? '',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (c.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              c.error!,
                              style: TextStyle(color: colors.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        StreamBuilder<Duration>(
                          stream: c.player.positionStream,
                          builder: (_, snapshot) {
                            final duration = c.player.duration ?? Duration.zero;
                            final max = duration.inMilliseconds.toDouble();
                            final value = (snapshot.data ?? c.player.position)
                                .inMilliseconds
                                .toDouble()
                                .clamp(0.0, max);
                            return Column(
                              children: [
                                Slider(
                                  value: value,
                                  max: max > 0 ? max : 1,
                                  onChanged: max > 0 && !c.loading
                                      ? (v) => c.seek(
                                          Duration(milliseconds: v.round()),
                                        )
                                      : null,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      clock(
                                        Duration(milliseconds: value.round()),
                                      ),
                                    ),
                                    Text(clock(duration)),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              tooltip: 'Chương trước',
                              onPressed: !c.loading && c.adjacent(-1) != null
                                  ? () => c.moveChapter(-1)
                                  : null,
                              icon: const Icon(Icons.skip_previous),
                            ),
                            TextButton(
                              onPressed: c.loading
                                  ? null
                                  : () => c.seek(
                                      c.player.position -
                                          const Duration(seconds: 15),
                                    ),
                              child: const Text('−15s'),
                            ),
                            SizedBox(
                              width: 68,
                              height: 68,
                              child: IconButton.filled(
                                tooltip: c.player.playing ? 'Tạm dừng' : 'Phát',
                                onPressed: c.loading ? null : c.toggle,
                                iconSize: 36,
                                icon: c.loading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        c.player.playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      ),
                              ),
                            ),
                            TextButton(
                              onPressed: c.loading
                                  ? null
                                  : () => c.seek(
                                      c.player.position +
                                          const Duration(seconds: 15),
                                    ),
                              child: const Text('+15s'),
                            ),
                            IconButton(
                              tooltip: 'Chương tiếp',
                              onPressed: !c.loading && c.adjacent(1) != null
                                  ? () => c.moveChapter(1)
                                  : null,
                              icon: const Icon(Icons.skip_next),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Tốc độ  '),
                            StreamBuilder<double>(
                              stream: c.player.speedStream,
                              builder: (_, snapshot) => DropdownButton<double>(
                                value: snapshot.data ?? c.player.speed,
                                items: [0.75, 1.0, 1.25, 1.5, 2.0]
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text('$v×'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) c.player.setSpeed(v);
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            TextButton.icon(
                              onPressed: () async {
                                await c.stop();
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.stop),
                              label: const Text('Dừng'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final id = chapter['id'] as String;
                            await c.stop();
                            if (context.mounted) {
                              context.go(RouteNames.readerChapter(id));
                            }
                          },
                          icon: const Icon(Icons.menu_book),
                          label: const Text('Đọc chương này'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tự chuyển sang chương tiếp theo khi đã có audio. Vị trí nghe được lưu riêng với tiến độ đọc.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
