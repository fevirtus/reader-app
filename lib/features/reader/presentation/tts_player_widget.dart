import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tts/tts_service.dart';

class TtsPlayerWidget extends ConsumerWidget {
  final String content;
  const TtsPlayerWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: tts.status != TtsStatus.idle ? notifier.skipBack : null,
          ),
          // Play/Pause/Stop
          if (!tts.isPlaying)
            IconButton.filled(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                if (tts.status == TtsStatus.paused) {
                  notifier.resume();
                  return;
                }
                notifier.startReading(
                  content,
                  paragraphIndex: tts.paragraphIndex,
                );
              },
            )
          else
            IconButton.filled(
              icon: const Icon(Icons.pause),
              onPressed: notifier.pause,
            ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: tts.status != TtsStatus.idle ? notifier.stop : null,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: tts.status != TtsStatus.idle ? notifier.skipForward : null,
          ),
          // Speed control
          PopupMenuButton<double>(
            initialValue: tts.speed,
            onSelected: notifier.setSpeed,
            icon: Text(
              '${tts.speed}x',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                .map((s) => PopupMenuItem(value: s, child: Text('${s}x')))
                .toList(),
          ),
          // Progress indicator
          if (tts.totalParagraphs > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${tts.paragraphIndex + 1}/${tts.totalParagraphs}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          if (tts.voiceName != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                tts.voiceName!,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                tts.language,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}
