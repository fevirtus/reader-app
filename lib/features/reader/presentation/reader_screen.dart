import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/chapter_model.dart';
import '../providers/reader_provider.dart';
import 'tts_player_widget.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCtrl.addListener(_onScroll);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onScroll() {
    ref.read(readerProvider.notifier).updateScroll(_scrollCtrl.offset);
  }

  void _toggleUI() => setState(() => _showUI = !_showUI);

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterProvider(widget.chapterId));
    final settings = ref.watch(readingSettingsProvider);

    return Scaffold(
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text('Lỗi tải chương: $e'),
              FilledButton(
                onPressed: () => ref.invalidate(chapterProvider(widget.chapterId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (chapter) {
          // Initialize progress tracking
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(readerProvider.notifier).open(
                  chapter.novelId,
                  chapter.id,
                  chapter.number,
                );
          });

          return GestureDetector(
            onTap: _toggleUI,
            child: Stack(
              children: [
                // Main content
                Scrollbar(
                  controller: _scrollCtrl,
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chương ${chapter.number}: ${chapter.title}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        SelectableText(
                          chapter.content,
                          style: TextStyle(
                            fontSize: settings.fontSize,
                            height: settings.lineHeight,
                            letterSpacing: settings.letterSpacing,
                            fontFamily: settings.fontFamily == 'serif' ? 'Georgia' : null,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _NavButtons(chapter: chapter),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                // Floating top bar
                AnimatedSlide(
                  offset: _showUI ? Offset.zero : const Offset(0, -1),
                  duration: const Duration(milliseconds: 200),
                  child: _TopBar(chapter: chapter),
                ),
                // Floating bottom bar with font controls
                AnimatedSlide(
                  offset: _showUI ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 200),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _BottomBar(settings: settings, onSettingsChanged: (s) {
                      ref.read(readingSettingsProvider.notifier).update(s);
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final ChapterModel chapter;
  const _TopBar({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withAlpha(230),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          chapter.volumeTitle ?? 'Chương ${chapter.number}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        leading: BackButton(onPressed: () => Navigator.maybePop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: () => context.push(
              RouteNames.commentsFor(chapter.novelId, chapterId: chapter.id),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over_outlined),
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Text-to-Speech',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TtsPlayerWidget(content: chapter.content),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final dynamic settings;
  final void Function(dynamic) onSettingsChanged;

  const _BottomBar({required this.settings, required this.onSettingsChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withAlpha(230),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Row(
        children: [
          const Icon(Icons.text_decrease, size: 18),
          Expanded(
            child: Slider(
              value: settings.fontSize,
              min: 12,
              max: 28,
              divisions: 8,
              onChanged: (v) => onSettingsChanged(settings.copyWith(fontSize: v)),
            ),
          ),
          const Icon(Icons.text_increase, size: 18),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.format_line_spacing),
            onPressed: () {
              final next = settings.lineHeight < 2.4
                  ? settings.lineHeight + 0.2
                  : 1.4;
              onSettingsChanged(settings.copyWith(lineHeight: next));
            },
          ),
        ],
      ),
    );
  }
}

class _NavButtons extends ConsumerWidget {
  final ChapterModel chapter;
  const _NavButtons({required this.chapter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (chapter.prevChapterId != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.pushReplacement(
                RouteNames.readerChapter(chapter.prevChapterId!),
              ),
              icon: const Icon(Icons.chevron_left),
              label: Text('Ch. ${chapter.prevChapterNumber ?? '?'}'),
            ),
          ),
        if (chapter.prevChapterId != null && chapter.nextChapterId != null)
          const SizedBox(width: 12),
        if (chapter.nextChapterId != null)
          Expanded(
            child: FilledButton.icon(
              onPressed: () => context.pushReplacement(
                RouteNames.readerChapter(chapter.nextChapterId!),
              ),
              icon: const Icon(Icons.chevron_right),
              label: Text('Ch. ${chapter.nextChapterNumber ?? '?'}'),
            ),
          ),
      ],
    );
  }
}
