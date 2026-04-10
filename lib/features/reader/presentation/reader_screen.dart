import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/reading_settings.dart';
import '../../../core/storage/local_store.dart';
import '../../novel/providers/novels_provider.dart';
import '../providers/reader_provider.dart';
import '../tts/tts_service.dart';
import 'tts_player_widget.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _uiAutoHideTimer;
  double _readingProgress = 0;
  String? _activeChapterId;
  bool _isRestoringProgress = false;
  bool _showQuickActions = true;
  double _lastScrollOffset = 0;
  double _scrollDeltaSinceToggle = 0;
  int _chapterDirection = 0; // -1: previous, 1: next
  int _lastAutoScrolledParagraph = -1;
  int _lastTtsCompletedCount = 0;
  String? _autoStartQueuedChapterId;
  final List<GlobalKey> _paragraphKeys = [];

  List<String> _paragraphsOf(String content) => content
      .split(RegExp(r'\n+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  String _chapterTopBarTitle(ChapterModel chapter) {
    final title = chapter.title.trim();
    if (title.isNotEmpty) return title;

    final volumeTitle = chapter.volumeTitle?.trim();
    if (volumeTitle != null && volumeTitle.isNotEmpty) return volumeTitle;

    return 'Chương ${chapter.number}';
  }

  TextAlign _textAlignFor(String value) {
    switch (value) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      default:
        return TextAlign.justify;
    }
  }

  Widget _buildParagraphText({
    required BuildContext context,
    required String paragraph,
    required TextStyle style,
    required TextAlign textAlign,
    required bool isActiveParagraph,
    required int highlightStart,
    required int highlightEnd,
    required Function(int charOffset) onSentenceTap,
  }) {
    final sentenceMatches = RegExp(r'[^.!?…]+[.!?…]*').allMatches(paragraph).toList();

    if (sentenceMatches.isEmpty) {
      return SelectableText(
        paragraph,
        textAlign: textAlign,
        style: style,
        onTap: () => onSentenceTap(0),
      );
    }

    final highlightStyle = style.copyWith(
      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(80),
      fontWeight: FontWeight.w600,
    );

    return SelectableText.rich(
      TextSpan(
        style: style,
        children: sentenceMatches.map((match) {
          final sentence = match.group(0)!;
          final start = match.start;
          final end = match.end;

          final isCurrentSpoken = isActiveParagraph &&
              highlightStart >= 0 &&
              highlightEnd > highlightStart &&
              start >= highlightStart &&
              end <= highlightEnd;

          return TextSpan(
            text: sentence,
            style: isCurrentSpoken ? highlightStyle : null,
            recognizer: TapGestureRecognizer()..onTap = () => onSentenceTap(start),
          );
        }).toList(),
      ),
      textAlign: textAlign,
    );
  }

  void _ensureParagraphKeys(int count) {
    if (_paragraphKeys.length == count) return;
    _paragraphKeys
      ..clear()
      ..addAll(List.generate(count, (_) => GlobalKey()));
    _lastAutoScrolledParagraph = -1;
  }

  void _maybeAutoScrollToTtsParagraph(TtsState tts, int paragraphCount) {
    if (tts.status == TtsStatus.idle) return;
    final index = tts.activeParagraphIndex;
    if (index < 0 || index >= paragraphCount) return;
    if (index == _lastAutoScrolledParagraph) return;

    _lastAutoScrolledParagraph = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _paragraphKeys[index].currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.22,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  int _firstVisibleParagraphIndex() {
    if (!_scrollCtrl.hasClients || _paragraphKeys.isEmpty) return 0;

    final viewportTop = _scrollCtrl.offset + 8;
    final viewportBottom =
        _scrollCtrl.offset + _scrollCtrl.position.viewportDimension - 8;

    int? partiallyVisibleIndex;

    for (var i = 0; i < _paragraphKeys.length; i++) {
      final ctx = _paragraphKeys[i].currentContext;
      if (ctx == null) continue;

      final renderObject = ctx.findRenderObject();
      if (renderObject == null || !renderObject.attached) continue;

      final viewport = RenderAbstractViewport.of(renderObject);

      final top = viewport.getOffsetToReveal(renderObject, 0).offset;
      final bottom = viewport.getOffsetToReveal(renderObject, 1).offset;

      final fullyVisible = top >= viewportTop && bottom <= viewportBottom;
      if (fullyVisible) return i;

      final partiallyVisible = bottom > viewportTop && top < viewportBottom;
      if (partiallyVisible && partiallyVisibleIndex == null) {
        partiallyVisibleIndex = i;
      }
    }

    return partiallyVisibleIndex ?? 0;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCtrl.addListener(_onScroll);
    });
  }

  /// Handle TTS state transitions that require navigation or restarts.
  /// Called once from [build] via [ref.listen] — safe to run side effects here.
  void _onTtsStateChanged(TtsState? previous, TtsState next) {
    // Guard: only act when something meaningful changed.
    if (previous == null) return;

    final chapterAsync = ref.read(chapterProvider(widget.chapterId));
    final chapter = chapterAsync.valueOrNull;
    if (chapter == null) return;

    // Chapter-completion → auto-advance to next chapter.
    if (next.completedCount > _lastTtsCompletedCount) {
      _lastTtsCompletedCount = next.completedCount;
      if (next.contentKey == chapter.id && chapter.nextChapterId != null) {
        final nextChapterId = chapter.nextChapterId!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(ttsProvider.notifier).scheduleAutoStartForChapter(nextChapterId);
          context.pushReplacement(RouteNames.readerChapter(nextChapterId));
        });
      }
      return;
    }

    // Pending auto-start for this chapter (set by previous chapter's completion).
    if (next.pendingAutoStartChapterId == chapter.id &&
        _autoStartQueuedChapterId != chapter.id) {
      _autoStartQueuedChapterId = chapter.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notifier = ref.read(ttsProvider.notifier);
        notifier.clearPendingAutoStartChapter();
        notifier.startReading(
          chapter.content,
          contentKey: chapter.id,
          title: 'Chương ${chapter.number}: ${chapter.title}',
        );
        _autoStartQueuedChapterId = null;
      });
    }
  }

  @override
  void dispose() {
    _uiAutoHideTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onScroll() {
    if (_isRestoringProgress) return;
    ref.read(readerProvider.notifier).updateScroll(_scrollCtrl.offset);

    final currentOffset = _scrollCtrl.hasClients ? _scrollCtrl.offset : _lastScrollOffset;
    final delta = currentOffset - _lastScrollOffset;
    if (_scrollDeltaSinceToggle == 0 ||
        (_scrollDeltaSinceToggle.isNegative == delta.isNegative)) {
      _scrollDeltaSinceToggle += delta;
    } else {
      _scrollDeltaSinceToggle = delta;
    }

    if (_showQuickActions && currentOffset > 120 && _scrollDeltaSinceToggle > 56) {
      setState(() => _showQuickActions = false);
      _scrollDeltaSinceToggle = 0;
    } else if (!_showQuickActions &&
        (_scrollDeltaSinceToggle < -36 || currentOffset <= 40)) {
      setState(() => _showQuickActions = true);
      _scrollDeltaSinceToggle = 0;
    }
    _lastScrollOffset = currentOffset;

    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    final next = max <= 0 ? 0.0 : (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    if ((next - _readingProgress).abs() > 0.01) {
      setState(() => _readingProgress = next);
    }
  }

  Future<void> _initializeChapterSession(ChapterModel chapter) async {
    if (_activeChapterId == chapter.id) return;
    _activeChapterId = chapter.id;
    _readingProgress = 0;

    ref.read(readerProvider.notifier).open(
          chapter.novelId,
          chapter.id,
          chapter.number,
        );

    final localStore = ref.read(localStoreProvider);
    final saved = await localStore.loadProgress(chapter.novelId);
    if (!mounted || saved == null) return;
    if (saved['chapterId'] != chapter.id) return;

    final savedOffset = (saved['scrollOffset'] as num?)?.toDouble() ?? 0;
    if (savedOffset <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      final target = savedOffset.clamp(0.0, max);

      _isRestoringProgress = true;
      _scrollCtrl.jumpTo(target);
      _isRestoringProgress = false;
      _onScroll();
    });
  }

  void _handleHorizontalSwipeEnd(DragEndDetails details, ChapterModel chapter) {
    final velocity = details.primaryVelocity ?? 0;
    const minVelocity = 300.0;

    if (velocity.abs() < minVelocity) return;

    // Swipe right -> previous chapter; swipe left -> next chapter
    if (velocity > 0 && chapter.prevChapterId != null) {
      _goToPreviousChapter(chapter);
      return;
    }

    if (velocity < 0 && chapter.nextChapterId != null) {
      _goToNextChapter(chapter);
    }
  }

  void _goToPreviousChapter(ChapterModel chapter) {
    final prevId = chapter.prevChapterId;
    if (prevId == null) return;
    setState(() => _chapterDirection = -1);
    HapticFeedback.selectionClick();
    context.pushReplacement(RouteNames.readerChapter(prevId));
  }

  void _goToNextChapter(ChapterModel chapter) {
    final nextId = chapter.nextChapterId;
    if (nextId == null) return;
    setState(() => _chapterDirection = 1);
    HapticFeedback.selectionClick();
    context.pushReplacement(RouteNames.readerChapter(nextId));
  }

  Future<void> _scrollToTop() async {
    if (!_scrollCtrl.hasClients) return;
    await _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openChapterToc(ChapterModel currentChapter) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final tocPage = ((currentChapter.number - 1) ~/ chapterPageSize) + 1;
            final chaptersAsync = ref.watch(
              chapterListProvider(
                ChapterListQuery(novelId: currentChapter.novelId, page: tocPage),
              ),
            );
            return FractionallySizedBox(
              heightFactor: 0.82,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mục lục chương',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: chaptersAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Không tải được mục lục: $e')),
                        data: (pageData) {
                          final chapters = pageData.chapters;
                          if (chapters.isEmpty) {
                            return const Center(child: Text('Chưa có danh sách chương.'));
                          }
                          return ListView.separated(
                            itemCount: chapters.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = chapters[index];
                              final isCurrent = item.id == currentChapter.id;
                              return ListTile(
                                dense: true,
                                selected: isCurrent,
                                selectedTileColor:
                                    Theme.of(context).colorScheme.primaryContainer.withAlpha(90),
                                title: Text(
                                  'Chương ${item.number}: ${item.title}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing:
                                    isCurrent ? const Icon(Icons.menu_book_rounded, size: 18) : null,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  if (!isCurrent) {
                                    context.pushReplacement(RouteNames.readerChapter(item.id));
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openReadingSettingsSheet(
    String previewContent,
    String chapterId,
    String chapterTitle,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(readingSettingsProvider);
            final tts = ref.watch(ttsProvider);
            final ttsNotifier = ref.read(ttsProvider.notifier);

            void closeSettingsSheet() {
              if (!sheetContext.mounted) return;
              final route = ModalRoute.of(sheetContext);
              if (route != null) {
                Navigator.of(sheetContext).removeRoute(route);
                return;
              }
              Navigator.of(sheetContext).maybePop();
            }

            Future<void> update(dynamic next) async {
              await ref.read(readingSettingsProvider.notifier).update(next);
            }

            return FractionallySizedBox(
              heightFactor: 0.92,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tùy chỉnh đọc', style: Theme.of(context).textTheme.headlineSmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tùy chỉnh văn bản, giao diện, bố cục và TTS ngay trong chương',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => update(const ReadingSettings()),
                              child: const Text('Mặc định'),
                            ),
                            IconButton(
                              onPressed: closeSettingsSheet,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: DefaultTabController(
                          length: 4,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: TabBar(
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                  dividerColor: Colors.transparent,
                                  labelPadding: const EdgeInsets.only(right: 8),
                                  indicator: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  labelColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                  tabs: const [
                                    Tab(child: _TabLabel(icon: Icons.text_fields, label: 'Văn bản')),
                                    Tab(child: _TabLabel(icon: Icons.palette_outlined, label: 'Giao diện')),
                                    Tab(child: _TabLabel(icon: Icons.view_day_outlined, label: 'Bố cục')),
                                    Tab(child: _TabLabel(icon: Icons.record_voice_over_outlined, label: 'TTS')),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    ListView(
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                      children: [
                                        _SettingsSection(
                                          title: 'Kiểu chữ',
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SegmentedButton<String>(
                                                segments: const [
                                                  ButtonSegment(value: 'serif', label: Text('Có chân')),
                                                  ButtonSegment(value: 'sans', label: Text('Không chân')),
                                                  ButtonSegment(value: 'mono', label: Text('Đơn cách')),
                                                ],
                                                selected: {settings.fontFamily},
                                                onSelectionChanged: (s) => update(settings.copyWith(fontFamily: s.first)),
                                              ),
                                              const SizedBox(height: 12),
                                              _LabeledSlider(
                                                label: 'Cỡ chữ',
                                                valueLabel: settings.fontSize.toStringAsFixed(0),
                                                min: 12,
                                                max: 32,
                                                divisions: 10,
                                                value: settings.fontSize,
                                                onChanged: (v) => update(settings.copyWith(fontSize: v)),
                                              ),
                                              _LabeledSlider(
                                                label: 'Giãn dòng',
                                                valueLabel: settings.lineHeight.toStringAsFixed(1),
                                                min: 1.2,
                                                max: 3.0,
                                                divisions: 9,
                                                value: settings.lineHeight,
                                                onChanged: (v) => update(settings.copyWith(lineHeight: v)),
                                              ),
                                              _LabeledSlider(
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
                                      ],
                                    ),
                                    ListView(
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                      children: [
                                        _SettingsSection(
                                          title: 'Giao diện đọc',
                                          child: Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: [
                                              _PresetChip(
                                                label: 'Sáng',
                                                value: 'paper',
                                                selected: settings.themePreset == 'paper',
                                                onTap: () => update(settings.copyWith(themePreset: 'paper')),
                                              ),
                                              _PresetChip(
                                                label: 'Sepia',
                                                value: 'sepia',
                                                selected: settings.themePreset == 'sepia',
                                                onTap: () => update(settings.copyWith(themePreset: 'sepia')),
                                              ),
                                              _PresetChip(
                                                label: 'Ban đêm',
                                                value: 'night',
                                                selected: settings.themePreset == 'night',
                                                onTap: () => update(settings.copyWith(themePreset: 'night')),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _SettingsSection(
                                          title: 'Mẫu nhanh',
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              FilledButton.tonal(
                                                onPressed: () => update(const ReadingSettings()),
                                                child: const Text('Mặc định'),
                                              ),
                                              FilledButton.tonal(
                                                onPressed: () => update(
                                                  settings.copyWith(
                                                    themePreset: 'night',
                                                    fontSize: 19,
                                                    lineHeight: 1.9,
                                                    textAlign: 'justify',
                                                  ),
                                                ),
                                                child: const Text('Đọc đêm'),
                                              ),
                                              FilledButton.tonal(
                                                onPressed: () => update(
                                                  settings.copyWith(
                                                    themePreset: 'sepia',
                                                    fontSize: 18,
                                                    lineHeight: 1.8,
                                                    textAlign: 'justify',
                                                  ),
                                                ),
                                                child: const Text('Thư giãn'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    ListView(
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                      children: [
                                        _SettingsSection(
                                          title: 'Bố cục trang',
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Canh chữ', style: Theme.of(context).textTheme.labelLarge),
                                              const SizedBox(height: 8),
                                              SegmentedButton<String>(
                                                segments: const [
                                                  ButtonSegment(value: 'left', label: Text('Trái')),
                                                  ButtonSegment(value: 'justify', label: Text('Đều')),
                                                  ButtonSegment(value: 'center', label: Text('Giữa')),
                                                ],
                                                selected: {settings.textAlign},
                                                onSelectionChanged: (s) => update(settings.copyWith(textAlign: s.first)),
                                              ),
                                              const SizedBox(height: 12),
                                              _LabeledSlider(
                                                label: 'Lề ngang',
                                                valueLabel: settings.horizontalPadding.toStringAsFixed(0),
                                                min: 12,
                                                max: 36,
                                                divisions: 8,
                                                value: settings.horizontalPadding,
                                                onChanged: (v) => update(settings.copyWith(horizontalPadding: v)),
                                              ),
                                              _LabeledSlider(
                                                label: 'Khoảng cách đoạn',
                                                valueLabel: settings.paragraphSpacing.toStringAsFixed(0),
                                                min: 8,
                                                max: 36,
                                                divisions: 7,
                                                value: settings.paragraphSpacing,
                                                onChanged: (v) => update(settings.copyWith(paragraphSpacing: v)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    ListView(
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                      children: [
                                        _SettingsSection(
                                          title: 'TTS tiếng Việt',
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      tts.voiceName ?? tts.language,
                                                      style: Theme.of(context).textTheme.titleSmall,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      formatTtsSpeedLabel(tts.speed),
                                                      style: Theme.of(context).textTheme.labelLarge,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [0.45, 0.675, 0.9, 1.125, 1.35, 1.8].map((speed) {
                                                  final selected = tts.speed == speed;
                                                  return ChoiceChip(
                                                    label: Text(formatTtsSpeedLabel(speed)),
                                                    selected: selected,
                                                    onSelected: (_) => ttsNotifier.setSpeed(speed),
                                                  );
                                                }).toList(),
                                              ),
                                              const SizedBox(height: 12),
                                              SwitchListTile.adaptive(
                                                contentPadding: EdgeInsets.zero,
                                                title: const Text('Chạy nền cho TTS'),
                                                subtitle: const Text(
                                                  'Tiếp tục đọc khi chuyển app hoặc tắt màn hình (Android)',
                                                ),
                                                value: tts.backgroundModeEnabled,
                                                onChanged: ttsNotifier.setBackgroundModeEnabled,
                                              ),
                                              if (tts.backgroundModeEnabled)
                                                ListTile(
                                                  contentPadding: EdgeInsets.zero,
                                                  title: const Text('Loại trừ tối ưu pin'),
                                                  subtitle: Text(
                                                    tts.batteryOptimizationIgnored
                                                        ? 'Đã bật: Android sẽ ít khả năng dừng TTS khi chạy nền.'
                                                        : 'Nên bật để Android không chặn TTS khi tắt màn hình.',
                                                  ),
                                                  trailing: tts.batteryOptimizationIgnored
                                                      ? const Icon(Icons.verified, color: Colors.green)
                                                      : OutlinedButton(
                                                          onPressed: ttsNotifier
                                                              .ensureBatteryOptimizationIgnored,
                                                          child: const Text('Bật ngay'),
                                                        ),
                                                ),
                                              const SizedBox(height: 12),
                                              if (tts.availableVietnameseVoices.isNotEmpty)
                                                DropdownButtonFormField<String>(
                                                  initialValue: tts.voiceName,
                                                  isExpanded: true,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Giọng đọc tiếng Việt',
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  items: tts.availableVietnameseVoices
                                                      .map(
                                                        (v) => DropdownMenuItem<String>(
                                                          value: v.name,
                                                          child: Text(
                                                            v.displayName,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      ttsNotifier.setVoiceByName(value);
                                                    }
                                                  },
                                                )
                                              else
                                                Text(
                                                  'Thiết bị không cung cấp nhiều giọng tiếng Việt. Đang dùng ${tts.voiceName ?? tts.language}.',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              const SizedBox(height: 12),
                                              TtsPlayerWidget(
                                                content: previewContent,
                                                contentKey: chapterId,
                                                title: 'Chương $chapterTitle',
                                                includeTitleOnStart: false,
                                                resolveStartParagraphIndex:
                                                    _firstVisibleParagraphIndex,
                                                onStarted: closeSettingsSheet,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterProvider(widget.chapterId));
    final settings = ref.watch(readingSettingsProvider);

    // Side-effects for TTS state changes (navigation, auto-start).
    ref.listen<TtsState>(ttsProvider, _onTtsStateChanged);
    Color readerBackground;
    Color readerTextColor;
    Color readerMutedColor;

    switch (settings.themePreset) {
      case 'night':
        readerBackground = const Color(0xFF101418);
        readerTextColor = const Color(0xFFE6EAF2);
        readerMutedColor = const Color(0xFFA5B0C5);
      case 'sepia':
        readerBackground = const Color(0xFFF6EAD7);
        readerTextColor = const Color(0xFF3B2F23);
        readerMutedColor = const Color(0xFF7A6753);
      default:
        readerBackground = const Color(0xFFFFFEF8);
        readerTextColor = const Color(0xFF111111);
        readerMutedColor = const Color(0xFF555555);
    }

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
          final paragraphs = _paragraphsOf(chapter.content);
          _ensureParagraphKeys(paragraphs.length);
          final textAlign = _textAlignFor(settings.textAlign);
          final novelAsync = ref.watch(novelDetailProvider(chapter.novelId));
          final tts = ref.watch(ttsProvider);
          final shouldHighlightTts = tts.contentKey == chapter.id &&
              (tts.status == TtsStatus.playing || tts.status == TtsStatus.paused);


          _maybeAutoScrollToTtsParagraph(tts, paragraphs.length);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeChapterSession(chapter);
          });

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) =>
                _handleHorizontalSwipeEnd(details, chapter),
            child: ColoredBox(
              color: readerBackground,
              child: Column(
                children: [
                  _TopBar(
                    title: _chapterTopBarTitle(chapter),
                    progress: _readingProgress,
                    onOpenSettings: () => _openReadingSettingsSheet(
                      chapter.content,
                      chapter.id,
                      'Chương ${chapter.number}: ${chapter.title}',
                    ),
                    barBackgroundColor: readerBackground,
                    foregroundColor: readerTextColor,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final beginOffset =
                            _chapterDirection < 0 ? const Offset(-0.08, 0) : const Offset(0.08, 0);
                        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
                        final slide = Tween<Offset>(
                          begin: beginOffset,
                          end: Offset.zero,
                        ).animate(fade);
                        return FadeTransition(
                          opacity: fade,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(chapter.id),
                        child: Scrollbar(
                          controller: _scrollCtrl,
                          child: SingleChildScrollView(
                            controller: _scrollCtrl,
                            padding: EdgeInsets.fromLTRB(
                              settings.horizontalPadding,
                              16,
                              settings.horizontalPadding,
                              24,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 760),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    novelAsync.when(
                                      loading: () => Text(
                                        'Đang tải tên truyện...',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: readerMutedColor,
                                            ),
                                      ),
                                      error: (_, _) => const SizedBox.shrink(),
                                      data: (novel) => Text(
                                        novel.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: readerMutedColor,
                                              letterSpacing: 0.2,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Chương ${chapter.number}: ${chapter.title}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(color: readerTextColor),
                                    ),
                                    const SizedBox(height: 20),
                                    if (chapter.content.trim().isEmpty)
                                      Text(
                                        'Chương này hiện chưa có nội dung.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: readerMutedColor),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          for (var index = 0; index < paragraphs.length; index++)
                                            Padding(
                                              key: _paragraphKeys[index],
                                              padding: EdgeInsets.only(
                                                bottom: index == paragraphs.length - 1
                                                    ? 0
                                                    : settings.paragraphSpacing,
                                              ),
                                              child: _buildParagraphText(
                                                context: context,
                                                paragraph: paragraphs[index],
                                                textAlign: textAlign,
                                                style: TextStyle(
                                                  color: readerTextColor,
                                                  fontSize: settings.fontSize,
                                                  height: settings.lineHeight,
                                                  letterSpacing: settings.letterSpacing,
                                                  fontFamily: settings.fontFamily == 'serif'
                                                      ? 'Georgia'
                                                      : settings.fontFamily == 'mono'
                                                          ? 'Courier'
                                                          : null,
                                                ),
                                                isActiveParagraph: shouldHighlightTts &&
                                                  tts.activeParagraphIndex == index,
                                                highlightStart: tts.progressStart,
                                                highlightEnd: tts.progressEnd,
                                                onSentenceTap: (charOffset) {
                                                  ref.read(ttsProvider.notifier).startReading(
                                                    chapter.content,
                                                    contentKey: chapter.id,
                                                    title: 'Chương ${chapter.number}: ${chapter.title}',
                                                    startParagraphIndex: index,
                                                    startCharOffset: charOffset,
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    const SizedBox(height: 40),
                                    _NavButtons(chapter: chapter),
                                    const SizedBox(height: 92),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: chapterAsync.hasValue
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              offset: _showQuickActions ? Offset.zero : const Offset(0, 1.4),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                opacity: _showQuickActions ? 1 : 0,
                child: Builder(
                  builder: (context) {
                    final chapter = chapterAsync.value!;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'reader-scroll-top',
                          onPressed: _scrollToTop,
                          child: const Icon(Icons.vertical_align_top_rounded, size: 20),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton.small(
                          heroTag: 'reader-toc',
                          onPressed: () => _openChapterToc(chapter),
                          child: const Icon(Icons.list_alt_rounded, size: 20),
                        ),
                      ],
                    );
                  },
                ),
              ),
            )
          : null,
      bottomNavigationBar: chapterAsync.whenOrNull(
        data: (chapter) {
          final tts = ref.watch(ttsProvider);
          final showMini = tts.contentKey == chapter.id &&
              (tts.status == TtsStatus.playing || tts.status == TtsStatus.paused);
          if (!showMini) return const SizedBox.shrink();

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: TtsPlayerWidget(
                compact: true,
                content: chapter.content,
                contentKey: chapter.id,
                title: 'Chương ${chapter.number}: ${chapter.title}',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final double progress;
  final VoidCallback onOpenSettings;
  final Color barBackgroundColor;
  final Color foregroundColor;

  const _TopBar({
    required this.title,
    required this.progress,
    required this.onOpenSettings,
    required this.barBackgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final progressText = '${(progress * 100).round()}%';
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: barBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.black.withAlpha(20)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: foregroundColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    progressText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Tùy chỉnh đọc',
                  icon: const Icon(Icons.tune, size: 20),
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _surfaceForPreset(String preset) {
  switch (preset) {
    case 'night':
      return const Color(0xFF101418);
    case 'sepia':
      return const Color(0xFFF6EAD7);
    default:
      return const Color(0xFFFFFEF8);
  }
}

Color _textForPreset(String preset) {
  switch (preset) {
    case 'night':
      return const Color(0xFFE6EAF2);
    case 'sepia':
      return const Color(0xFF3B2F23);
    default:
      return const Color(0xFF111111);
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
              Text(valueLabel, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          Slider(
            min: min,
            max: max,
            divisions: divisions,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceForPreset(value),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: _surfaceForPreset(value),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _textForPreset(value).withAlpha(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aa',
                      style: TextStyle(
                        color: _textForPreset(value),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 3,
                      width: 54,
                      decoration: BoxDecoration(
                        color: _textForPreset(value).withAlpha(110),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label),
      ],
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
              label: Text('Chương ${chapter.prevChapterNumber ?? '?'}'),
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
              label: Text('Chương ${chapter.nextChapterNumber ?? '?'}'),
            ),
          ),
      ],
    );
  }
}
