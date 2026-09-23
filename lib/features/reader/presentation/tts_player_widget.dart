import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tts/tts_service.dart';
import '../../../core/audio/sleep_timer_button.dart';

class TtsPlayerWidget extends ConsumerWidget {
  const TtsPlayerWidget({
    super.key,
    required this.content,
    this.contentKey,
    this.title,
    this.nextChapterId,
    this.chapterNumber,
    this.apiBaseUrl,
    this.includeTitleOnStart = true,
    this.resolveStartParagraphIndex,
    this.onStarted,
    this.compact = false,
  });

  final String content;
  final String? contentKey;
  final String? title;
  final String? nextChapterId;
  final int? chapterNumber;
  final String? apiBaseUrl;
  final bool includeTitleOnStart;
  final int Function()? resolveStartParagraphIndex;
  final VoidCallback? onStarted;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);

    const speeds = [0.45, 0.675, 0.9, 1.125, 1.35, 1.8];

    Future<void> start() async {
      if (tts.status == TtsStatus.paused && tts.contentKey == contentKey) {
        unawaited(notifier.resume());
        onStarted?.call();
        return;
      }

      notifier.clearPendingAutoStartChapter();

      unawaited(
        notifier.startReading(
          content,
          paragraphIndex: tts.contentKey == contentKey ? tts.paragraphIndex : 0,
          startParagraphIndex: resolveStartParagraphIndex?.call(),
          contentKey: contentKey,
          title: title,
          nextChapterId: nextChapterId,
          chapterNumber: chapterNumber,
          apiBaseUrl: apiBaseUrl,
          includeTitle: includeTitleOnStart,
        ),
      );
      onStarted?.call();
    }

    Widget speedButton() {
      return PopupMenuButton<double>(
        initialValue: tts.speed,
        onSelected: notifier.setSpeed,
        icon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Theme.of(context).colorScheme.surface.withAlpha(170),
          ),
          child: Text(
            formatTtsSpeedLabel(tts.speed),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        itemBuilder: (_) => speeds
            .map(
              (s) =>
                  PopupMenuItem(value: s, child: Text(formatTtsSpeedLabel(s))),
            )
            .toList(),
      );
    }

    if (compact) {
      final progressValue = tts.totalParagraphs > 0
          ? ((tts.paragraphIndex + 1) / tts.totalParagraphs).clamp(0.0, 1.0)
          : 0.0;

      return SizedBox(
        height: 82,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(180),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title?.trim().isNotEmpty == true
                              ? title!
                              : 'Đang phát TTS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          tts.errorMessage != null
                              ? tts.errorMessage!
                              : tts.isBuffering
                              ? 'Đang chuẩn bị chương tiếp theo…'
                              : tts.totalParagraphs > 0
                              ? 'Câu ${tts.paragraphIndex + 1}/${tts.totalParagraphs}'
                              : (tts.voiceName ?? tts.language),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  if (!tts.isPlaying)
                    IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: () => start(),
                    )
                  else
                    IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.pause_rounded),
                      onPressed: notifier.pause,
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.stop_rounded),
                    onPressed: tts.status != TtsStatus.idle
                        ? notifier.stop
                        : null,
                  ),
                  const SleepTimerButton(compact: true),
                  speedButton(),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: tts.isBuffering ? null : progressValue,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withAlpha(120),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: tts.status != TtsStatus.idle
                    ? notifier.skipBack
                    : null,
              ),
              if (!tts.isPlaying)
                IconButton.filled(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => start(),
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
                onPressed: tts.status != TtsStatus.idle
                    ? notifier.skipForward
                    : null,
              ),
              speedButton(),
              const SleepTimerButton(),
            ],
          ),
          const SizedBox(height: 6),
          if (tts.isBuffering) const Text('Đang chuẩn bị chương tiếp theo…'),
          if (tts.errorMessage != null) Text(tts.errorMessage!),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (tts.totalParagraphs > 0)
                Text(
                  '${tts.paragraphIndex + 1}/${tts.totalParagraphs}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              Text(
                tts.voiceName ?? tts.language,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
