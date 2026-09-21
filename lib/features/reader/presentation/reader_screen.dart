import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/reading_settings.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/settings_controls.dart';
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

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  static const List<Color> _backgroundColorChoices = [
    Color(0xFFFFFEF8),
    Color(0xFFF6EAD7),
    Color(0xFF101418),
    Color(0xFFF3F7FF),
    Color(0xFFF6FFF5),
  ];

  static const List<Color> _textColorChoices = [
    Color(0xFF111111),
    Color(0xFF2C1E12),
    Color(0xFFE6EAF2),
    Color(0xFF1F2A44),
    Color(0xFF0F5132),
  ];

  final ScrollController _scrollCtrl = ScrollController();
  Timer? _uiAutoHideTimer;
  final ValueNotifier<double> _readingProgress = ValueNotifier(0);
  final ValueNotifier<bool> _showQuickActions = ValueNotifier(true);
  String? _activeChapterId;
  bool _isRestoringProgress = false;
  double _lastScrollOffset = 0;
  double _scrollDeltaSinceToggle = 0;
  double _lastReportedOffset = 0;
  DateTime? _lastReportedAt;
  int _chapterDirection = 0; // -1: previous, 1: next
  int _lastAutoScrolledParagraph = -1;
  int _lastTtsCompletedCount = 0;
  String? _autoStartQueuedChapterId;
  final List<GlobalKey> _paragraphKeys = [];
  String? _sentenceSlicesChapterId;
  List<List<_SentenceSlice>> _sentenceSlicesByParagraph = const [];

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
        return TextAlign.left;
    }
  }

  Widget _buildParagraphText({
    required BuildContext context,
    required List<_SentenceSlice> sentenceSlices,
    required TextStyle style,
    required TextStyle highlightStyle,
    required TextAlign textAlign,
    required bool isActiveParagraph,
    required int highlightStart,
    required int highlightEnd,
    required Function(int charOffset) onSentenceTap,
    // When true, renders Text.rich instead of SelectableText.rich.
    // This avoids the "selection.isValid" assertion that fires when a
    // TapGestureRecognizer on a span triggers TTS/scroll while SelectableText
    // still holds a stale internal selection.
    bool useTapRecognizer = false,
  }) {
    final spans = sentenceSlices.map((slice) {
      final start = slice.start;
      final end = slice.end;

      final isCurrentSpoken = isActiveParagraph &&
          highlightStart >= 0 &&
          highlightEnd > highlightStart &&
          start >= highlightStart &&
          end <= highlightEnd;

      if (!useTapRecognizer) {
        return TextSpan(
          text: slice.text,
          style: isCurrentSpoken ? highlightStyle : null,
        );
      }

      // Use WidgetSpan + GestureDetector to avoid lifecycle issues from
      // creating/discarding many TapGestureRecognizer instances across rebuilds.
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // Unfocus immediately so SelectableText drops its selection state
            // before any scroll notification can call getBoxesForSelection.
            FocusManager.instance.primaryFocus?.unfocus();
            onSentenceTap(start);
          },
          child: Text(
            slice.text,
            style: isCurrentSpoken ? highlightStyle : style,
          ),
        ),
      );
    }).toList();

    final textSpan = TextSpan(style: style, children: spans);

    if (useTapRecognizer || sentenceSlices.isEmpty) {
      // Use plain Text.rich when sentence-tap TTS is active.
      // SelectableText keeps an internal TextEditingController/selection that
      // becomes invalid after a programmatic rebuild, causing a Flutter
      // assertion failure in getBoxesForSelection during scroll.
      return GestureDetector(
        onTap: sentenceSlices.isEmpty ? () => onSentenceTap(0) : null,
        child: RichText(text: textSpan, textAlign: textAlign),
      );
    }

    return SelectableText.rich(textSpan, textAlign: textAlign);
  }

  List<List<_SentenceSlice>> _sentenceSlicesForChapter(
    ChapterModel chapter,
    List<String> paragraphs,
  ) {
    if (_sentenceSlicesChapterId == chapter.id &&
        _sentenceSlicesByParagraph.length == paragraphs.length) {
      return _sentenceSlicesByParagraph;
    }

    final sentencePattern = RegExp(r'[^.!?…]+[.!?…]*');
    final parsed = <List<_SentenceSlice>>[];

    for (final paragraph in paragraphs) {
      final matches = sentencePattern.allMatches(paragraph).toList();
      if (matches.isEmpty) {
        parsed.add([
          _SentenceSlice(text: paragraph, start: 0, end: paragraph.length),
        ]);
        continue;
      }

      parsed.add(
        matches
            .map(
              (match) => _SentenceSlice(
                text: match.group(0)!,
                start: match.start,
                end: match.end,
              ),
            )
            .toList(),
      );
    }

    _sentenceSlicesChapterId = chapter.id;
    _sentenceSlicesByParagraph = parsed;
    return parsed;
  }

  void _ensureParagraphKeys(int count) {
    if (_paragraphKeys.length == count) return;
    _paragraphKeys
      ..clear()
      ..addAll(List.generate(count, (_) => GlobalKey()));
    _lastAutoScrolledParagraph = -1;
  }

  void _maybeAutoScrollToTtsParagraph(TtsState tts, int paragraphCount) {
    if (tts.status != TtsStatus.playing) return;
    final index = tts.activeParagraphIndex;
    if (index < 0 || index >= paragraphCount) return;
    if (index == _lastAutoScrolledParagraph) return;

    _lastAutoScrolledParagraph = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _paragraphKeys[index].currentContext;
      if (ctx == null) return;
      // Clear any active text-selection focus before programmatic scrolling.
      FocusManager.instance.primaryFocus?.unfocus();
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

  Future<void> _reconcileChapterWithNativeTts() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final notifier = ref.read(ttsProvider.notifier);
    await notifier.refreshNativeSnapshot();
    if (!mounted) return;

    final tts = ref.read(ttsProvider);
    final targetChapterId = tts.contentKey;
    if (targetChapterId == null || targetChapterId.isEmpty) return;
    if (targetChapterId == widget.chapterId) return;
    if (tts.status != TtsStatus.playing && tts.status != TtsStatus.paused) return;

    context.pushReplacement(RouteNames.readerChapter(targetChapterId));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_reconcileChapterWithNativeTts());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_reconcileChapterWithNativeTts());
    }
  }

  /// Handle TTS state transitions that require navigation or restarts.
  /// Called once from [build] via [ref.listen] — safe to run side effects here.
  void _onTtsStateChanged(TtsState? previous, TtsState next) {
    // Guard: only act when something meaningful changed.
    if (previous == null) return;

    final chapterAsync = ref.read(chapterProvider(widget.chapterId));
    final chapter = chapterAsync.valueOrNull;
    if (chapter == null) return;

    if (previous.contentKey == chapter.id &&
        next.contentKey != null &&
        next.contentKey != chapter.id &&
        next.contentKey != previous.contentKey &&
        (next.status == TtsStatus.playing || next.status == TtsStatus.paused)) {
      final targetChapterId = next.contentKey!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushReplacement(RouteNames.readerChapter(targetChapterId));
      });
      return;
    }

    // Chapter-completion → auto-advance to next chapter.
    // On Android, native service already fetches and starts next chapter.
    // Re-queueing auto-start from UI causes duplicate START_READING races.
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (next.completedCount > _lastTtsCompletedCount) {
        _lastTtsCompletedCount = next.completedCount;
      }
      return;
    }

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
          nextChapterId: chapter.nextChapterId,
          chapterNumber: chapter.number,
          apiBaseUrl: AppConfig.baseUrl,
        );
        _autoStartQueuedChapterId = null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiAutoHideTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _readingProgress.dispose();
    _showQuickActions.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  bool _shouldReportScroll(double offset) {
    final now = DateTime.now();
    final elapsedMs = _lastReportedAt == null
        ? 1000
        : now.difference(_lastReportedAt!).inMilliseconds;
    final delta = (offset - _lastReportedOffset).abs();
    return delta >= 24 || elapsedMs >= 700;
  }

  void _onScroll() {
    if (_isRestoringProgress) return;
    final offset = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
    if (_shouldReportScroll(offset)) {
      _lastReportedOffset = offset;
      _lastReportedAt = DateTime.now();
      ref.read(readerProvider.notifier).updateScroll(offset);
    }

    final currentOffset = _scrollCtrl.hasClients ? _scrollCtrl.offset : _lastScrollOffset;
    final delta = currentOffset - _lastScrollOffset;
    if (_scrollDeltaSinceToggle == 0 ||
        (_scrollDeltaSinceToggle.isNegative == delta.isNegative)) {
      _scrollDeltaSinceToggle += delta;
    } else {
      _scrollDeltaSinceToggle = delta;
    }

    if (_showQuickActions.value && currentOffset > 120 && _scrollDeltaSinceToggle > 56) {
      _showQuickActions.value = false;
      _scrollDeltaSinceToggle = 0;
    } else if (!_showQuickActions.value &&
        (_scrollDeltaSinceToggle < -36 || currentOffset <= 40)) {
      _showQuickActions.value = true;
      _scrollDeltaSinceToggle = 0;
    }
    _lastScrollOffset = currentOffset;

    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    final next = max <= 0 ? 0.0 : (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    if ((next - _readingProgress.value).abs() > 0.02) {
      _readingProgress.value = next;
    }
  }

  Future<void> _initializeChapterSession(ChapterModel chapter) async {
    if (_activeChapterId == chapter.id) return;
    final previousChapterId = _activeChapterId;
    final switchedChapter = previousChapterId != null && previousChapterId != chapter.id;
    _activeChapterId = chapter.id;
    _readingProgress.value = 0;
    _showQuickActions.value = true;
    _lastScrollOffset = 0;
    _scrollDeltaSinceToggle = 0;
    _lastReportedOffset = 0;
    _lastReportedAt = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _isRestoringProgress = true;
      _scrollCtrl.jumpTo(0);
      _isRestoringProgress = false;
    });

    ref.read(readerProvider.notifier).open(
          chapter.novelId,
          chapter.id,
          chapter.number,
        );

    _consumePendingAutoStartForChapter(chapter);

    if (switchedChapter) {
      ref.read(readerProvider.notifier).resetCurrentChapterProgress();
      return;
    }

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
      _lastReportedOffset = target;
      _lastReportedAt = DateTime.now();
      _onScroll();
    });
  }

  void _goToPreviousChapter(ChapterModel chapter) {
    final prevId = chapter.prevChapterId;
    if (prevId == null) return;
    setState(() => _chapterDirection = -1);
    HapticFeedback.selectionClick();
    _queueAutoStartIfReadingCurrentChapter(chapter.id, prevId);
    context.pushReplacement(RouteNames.readerChapter(prevId));
  }

  void _goToNextChapter(ChapterModel chapter) {
    final nextId = chapter.nextChapterId;
    if (nextId == null) return;
    setState(() => _chapterDirection = 1);
    HapticFeedback.selectionClick();
    _queueAutoStartIfReadingCurrentChapter(chapter.id, nextId);
    context.pushReplacement(RouteNames.readerChapter(nextId));
  }

  void _queueAutoStartIfReadingCurrentChapter(
    String currentChapterId,
    String targetChapterId,
  ) {
    final tts = ref.read(ttsProvider);
    // Only auto-start on the target chapter when TTS is actively PLAYING.
    // If paused, the user intentionally stopped – do not resume on navigation.
    final isActivelyPlaying = tts.contentKey == currentChapterId &&
        tts.status == TtsStatus.playing;
    if (!isActivelyPlaying) return;
    ref.read(ttsProvider.notifier).scheduleAutoStartForChapter(targetChapterId);
  }

  void _consumePendingAutoStartForChapter(ChapterModel chapter) {
    final tts = ref.read(ttsProvider);
    if (tts.pendingAutoStartChapterId != chapter.id) return;
    if (_autoStartQueuedChapterId == chapter.id) return;

    // If native TTS service already moved to this chapter and is actively
    // controlling playback, do not issue another manual START_READING.
    final isAlreadyPlayingThisChapter =
        tts.contentKey == chapter.id &&
        (tts.status == TtsStatus.playing || tts.status == TtsStatus.paused);
    if (isAlreadyPlayingThisChapter) {
      ref.read(ttsProvider.notifier).clearPendingAutoStartChapter();
      return;
    }

    _autoStartQueuedChapterId = chapter.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(ttsProvider.notifier);
      notifier.clearPendingAutoStartChapter();
      notifier.startReading(
        chapter.content,
        contentKey: chapter.id,
        title: 'Chương ${chapter.number}: ${chapter.title}',
        nextChapterId: chapter.nextChapterId,
        chapterNumber: chapter.number,
        apiBaseUrl: AppConfig.baseUrl,
      );
      _autoStartQueuedChapterId = null;
    });
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
            final chaptersAsync = ref.watch(
              chapterListProvider(currentChapter.novelId),
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
                        data: (chapters) {
                          if (chapters.isEmpty) {
                            return const Center(child: Text('Chưa có danh sách chương.'));
                          }
                          // Find index of current chapter for auto-scroll
                          final currentIndex = chapters.indexWhere((ch) => ch.id == currentChapter.id);
                          final scrollController = ScrollController(
                            initialScrollOffset: currentIndex > 0
                                ? currentIndex * 48.0 // Approximate height per ListTile
                                : 0,
                          );
                          
                          return ListView.separated(
                            controller: scrollController,
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
                                    _queueAutoStartIfReadingCurrentChapter(
                                      currentChapter.id,
                                      item.id,
                                    );
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
    String? nextChapterId,
    int? chapterNumber,
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
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final isCompactTabs = MediaQuery.sizeOf(context).width < 380;

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
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withAlpha(180),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant.withAlpha(160),
                                    ),
                                  ),
                                  child: TabBar(
                                    isScrollable: false,
                                    dividerColor: Colors.transparent,
                                    padding: EdgeInsets.zero,
                                    labelPadding: EdgeInsets.zero,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    splashBorderRadius: BorderRadius.circular(18),
                                    overlayColor: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.pressed)) {
                                        return colorScheme.primary.withAlpha(18);
                                      }
                                      return null;
                                    }),
                                    indicator: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(16),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    labelColor: colorScheme.onSurface,
                                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                                    tabs: [
                                      _TabLabel(
                                        icon: Icons.text_fields_rounded,
                                        label: 'Văn bản',
                                        compact: isCompactTabs,
                                      ),
                                      _TabLabel(
                                        icon: Icons.palette_outlined,
                                        label: 'Giao diện',
                                        compact: isCompactTabs,
                                      ),
                                      _TabLabel(
                                        icon: Icons.tune_rounded,
                                        label: 'Bố cục',
                                        compact: isCompactTabs,
                                      ),
                                      _TabLabel(
                                        icon: Icons.record_voice_over_outlined,
                                        label: 'TTS',
                                        compact: isCompactTabs,
                                      ),
                                    ],
                                  ),
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
                                        SettingsSection(
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
                                                selected: {
                                                  {'serif', 'sans', 'mono'}.contains(settings.fontFamily)
                                                      ? settings.fontFamily
                                                      : 'serif',
                                                },
                                                onSelectionChanged: (s) => update(
                                                  settings.copyWith(fontFamily: s.first),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
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
                                      ],
                                    ),
                                    ListView(
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                      children: [
                                        SettingsSection(
                                          title: 'Giao diện đọc',
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Màu nền',
                                                style: Theme.of(context).textTheme.labelLarge,
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 10,
                                                runSpacing: 10,
                                                children: _backgroundColorChoices.map((color) {
                                                  return ColorOptionChip(
                                                    color: color,
                                                    selected: settings.backgroundColorValue == color.toARGB32(),
                                                    onTap: () => update(
                                                      settings.copyWith(backgroundColorValue: color.toARGB32()),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              const SizedBox(height: 14),
                                              Text(
                                                'Màu chữ',
                                                style: Theme.of(context).textTheme.labelLarge,
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 10,
                                                runSpacing: 10,
                                                children: _textColorChoices.map((color) {
                                                  return ColorOptionChip(
                                                    color: color,
                                                    selected: settings.textColorValue == color.toARGB32(),
                                                    onTap: () => update(
                                                      settings.copyWith(textColorValue: color.toARGB32()),
                                                    ),
                                                  );
                                                }).toList(),
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
                                        SettingsSection(
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
                                              LabeledSlider(
                                                label: 'Lề ngang',
                                                valueLabel: settings.horizontalPadding.toStringAsFixed(0),
                                                min: 12,
                                                max: 36,
                                                divisions: 8,
                                                value: settings.horizontalPadding,
                                                onChanged: (v) => update(settings.copyWith(horizontalPadding: v)),
                                              ),
                                              LabeledSlider(
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
                                        SettingsSection(
                                          title: 'TTS tiếng Việt',
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SwitchListTile.adaptive(
                                                contentPadding: EdgeInsets.zero,
                                                value: settings.enableSentenceTapTts,
                                                onChanged: (enabled) {
                                                  unawaited(
                                                    ref
                                                        .read(readingSettingsProvider.notifier)
                                                        .setSentenceTapTtsEnabled(enabled),
                                                  );
                                                },
                                                title: const Text('Bật chạm câu để phát TTS'),
                                                subtitle: const Text(
                                                  'Tắt để tránh chạm nhầm làm bắt đầu TTS.',
                                                ),
                                              ),
                                              const SizedBox(height: 8),
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
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondaryContainer
                                                      .withAlpha(90),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Theme.of(context).colorScheme.outlineVariant,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Điều kiện bắt buộc để TTS chạy ổn định',
                                                      style: Theme.of(context).textTheme.titleSmall,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          tts.backgroundModeEnabled
                                                              ? Icons.check_circle
                                                              : Icons.radio_button_unchecked,
                                                          size: 18,
                                                          color: tts.backgroundModeEnabled
                                                              ? _successColor(context)
                                                              : Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        const Expanded(
                                                          child: Text(
                                                            'Bật chạy nền cho TTS',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          tts.batteryOptimizationIgnored
                                                              ? Icons.check_circle
                                                              : Icons.radio_button_unchecked,
                                                          size: 18,
                                                          color: tts.batteryOptimizationIgnored
                                                              ? _successColor(context)
                                                              : Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        const Expanded(
                                                          child: Text(
                                                            'Loại trừ tối ưu pin',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Align(
                                                      alignment: Alignment.centerRight,
                                                      child: OutlinedButton(
                                                        onPressed: () async {
                                                          await ttsNotifier.setBackgroundModeEnabled(true);
                                                          await ttsNotifier.ensureBatteryOptimizationIgnored();
                                                        },
                                                        child: const Text('Bật ngay'),
                                                      ),
                                                    ),
                                                  ],
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
                                                nextChapterId: nextChapterId,
                                                chapterNumber: chapterNumber,
                                                apiBaseUrl: AppConfig.baseUrl,
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
    final readerBackground = Color(settings.backgroundColorValue);
    final readerTextColor = Color(settings.textColorValue);
    final readerMutedColor = readerTextColor.withAlpha(170);

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
          final sentenceSlicesByParagraph =
              _sentenceSlicesForChapter(chapter, paragraphs);
          final textAlign = _textAlignFor(settings.textAlign);
          final novelAsync = ref.watch(novelDetailProvider(chapter.novelId));
          final tts = ref.watch(ttsProvider);
          final shouldHighlightTts = tts.contentKey == chapter.id &&
              (tts.status == TtsStatus.playing || tts.status == TtsStatus.paused);
          final paragraphStyle = TextStyle(
            color: readerTextColor,
            fontSize: settings.fontSize,
            height: settings.lineHeight,
            letterSpacing: settings.letterSpacing,
            fontFamily: _resolveReaderFontFamily(settings.fontFamily),
          );
          final paragraphHighlightStyle = paragraphStyle.copyWith(
            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(80),
            fontWeight: FontWeight.w600,
          );


          _maybeAutoScrollToTtsParagraph(tts, paragraphs.length);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeChapterSession(chapter);
          });

          return ColoredBox(
            color: readerBackground,
            child: Column(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _readingProgress,
                    builder: (context, progress, _) {
                      return _TopBar(
                        title: _chapterTopBarTitle(chapter),
                        progress: progress,
                        onOpenSettings: () => _openReadingSettingsSheet(
                          chapter.content,
                          chapter.id,
                          'Chương ${chapter.number}: ${chapter.title}',
                          chapter.nextChapterId,
                          chapter.number,
                        ),
                        barBackgroundColor: readerBackground,
                        foregroundColor: readerTextColor,
                      );
                    },
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
                          child: CustomScrollView(
                            controller: _scrollCtrl,
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  settings.horizontalPadding,
                                  16,
                                  settings.horizontalPadding,
                                  chapter.content.trim().isEmpty ? 24 : 0,
                                ),
                                sliver: SliverToBoxAdapter(
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
                                          const SizedBox(height: 12),
                                          _NavButtons(
                                            chapter: chapter,
                                            onGoPrevious: () => _goToPreviousChapter(chapter),
                                            onGoNext: () => _goToNextChapter(chapter),
                                          ),
                                          const SizedBox(height: 20),
                                          if (chapter.content.trim().isEmpty)
                                            Text(
                                              'Chương này hiện chưa có nội dung.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(color: readerMutedColor),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (chapter.content.trim().isNotEmpty)
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    settings.horizontalPadding,
                                    0,
                                    settings.horizontalPadding,
                                    0,
                                  ),
                                  sliver: SliverList.builder(
                                    itemCount: paragraphs.length,
                                    itemBuilder: (context, index) {
                                      final sentenceSlices = sentenceSlicesByParagraph[index];
                                      return Align(
                                        alignment: Alignment.topCenter,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 760),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: Padding(
                                              key: _paragraphKeys[index],
                                              padding: EdgeInsets.only(
                                                bottom: index == paragraphs.length - 1
                                                    ? 0
                                                    : settings.paragraphSpacing,
                                              ),
                                              child: _buildParagraphText(
                                                context: context,
                                                sentenceSlices: sentenceSlices,
                                                textAlign: textAlign,
                                                style: paragraphStyle,
                                                highlightStyle: paragraphHighlightStyle,
                                                isActiveParagraph: shouldHighlightTts &&
                                                    tts.activeParagraphIndex == index,
                                                highlightStart: tts.progressStart,
                                                highlightEnd: tts.progressEnd,
                                                onSentenceTap: (charOffset) {
                                                  final hasActiveTtsSession =
                                                      tts.contentKey == chapter.id &&
                                                      (tts.status == TtsStatus.playing ||
                                                          tts.status == TtsStatus.paused);
                                                  final canStartFromSentence =
                                                      settings.enableSentenceTapTts || hasActiveTtsSession;
                                                  if (!canStartFromSentence) {
                                                    return;
                                                  }
                                                  // Synchronous unfocus clears stale SelectableText selection
                                                  // before startReading triggers a widget rebuild + scroll.
                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                  ref
                                                      .read(ttsProvider.notifier)
                                                      .clearPendingAutoStartChapter();
                                                  ref.read(ttsProvider.notifier).startReading(
                                                    chapter.content,
                                                    contentKey: chapter.id,
                                                    title: 'Chương ${chapter.number}: ${chapter.title}',
                                                    nextChapterId: chapter.nextChapterId,
                                                    chapterNumber: chapter.number,
                                                    apiBaseUrl: AppConfig.baseUrl,
                                                    startParagraphIndex: index,
                                                    startCharOffset: charOffset,
                                                  );
                                                },
                                                useTapRecognizer: settings.enableSentenceTapTts ||
                                                    (tts.contentKey == chapter.id &&
                                                        (tts.status == TtsStatus.playing ||
                                                            tts.status == TtsStatus.paused)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  settings.horizontalPadding,
                                  40,
                                  settings.horizontalPadding,
                                  92,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 760),
                                      child: _NavButtons(
                                        chapter: chapter,
                                        onGoPrevious: () => _goToPreviousChapter(chapter),
                                        onGoNext: () => _goToNextChapter(chapter),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          );
        },
      ),
      floatingActionButton: chapterAsync.hasValue
          ? ValueListenableBuilder<bool>(
              valueListenable: _showQuickActions,
              builder: (context, showQuickActions, _) {
                return AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  offset: showQuickActions ? Offset.zero : const Offset(0, 1.4),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: showQuickActions ? 1 : 0,
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
                );
              },
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
                nextChapterId: chapter.nextChapterId,
                chapterNumber: chapter.number,
                apiBaseUrl: AppConfig.baseUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SentenceSlice {
  const _SentenceSlice({
    required this.text,
    required this.start,
    required this.end,
  });

  final String text;
  final int start;
  final int end;
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

Color _successColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkSuccess
      : AppColors.lightSuccess;
}

String? _resolveReaderFontFamily(String fontFamily) {
  switch (fontFamily) {
    case 'serif':
    case 'georgia':
      return 'Georgia';
    case 'mono':
      return 'Courier';
    case 'roboto':
      return 'Roboto';
    case 'sans':
    default:
      return null;
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: compact ? 12.5 : 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        );

    return SizedBox(
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact) ...[
                  Icon(icon, size: 16),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: textStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  final ChapterModel chapter;
  final VoidCallback onGoPrevious;
  final VoidCallback onGoNext;

  const _NavButtons({
    required this.chapter,
    required this.onGoPrevious,
    required this.onGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (chapter.prevChapterId != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onGoPrevious,
              child: Text('< Chương ${chapter.prevChapterNumber ?? '?'}'),
            ),
          ),
        if (chapter.prevChapterId != null && chapter.nextChapterId != null)
          const SizedBox(width: 12),
        if (chapter.nextChapterId != null)
          Expanded(
            child: FilledButton(
              onPressed: onGoNext,
              child: Text('> Chương ${chapter.nextChapterNumber ?? '?'}'),
            ),
          ),
      ],
    );
  }
}
