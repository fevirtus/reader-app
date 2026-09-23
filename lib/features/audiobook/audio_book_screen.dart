import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/providers.dart';
import 'audio_book_controller.dart';
import 'audio_book_voice_picker.dart';
import 'audio_book_player_screen.dart';

class AudioBookScreen extends ConsumerStatefulWidget {
  const AudioBookScreen({
    super.key,
    required this.novelId,
    this.initialChapterId,
  });
  final String novelId;
  final String? initialChapterId;
  @override
  ConsumerState<AudioBookScreen> createState() => _AudioBookScreenState();
}

class _AudioBookScreenState extends ConsumerState<AudioBookScreen> {
  List<AudioJson> _remote = [], _voices = [];
  String? _selected, _error;
  String _requestVoice = 'anh-khoi';
  String? _novelTitle;
  bool _loading = true, _requesting = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  Future<void> _load() async {
    final controller = ref.read(audioBookControllerProvider);
    final prefs = await SharedPreferences.getInstance();
    final progress = jsonDecode(
      prefs.getString(controller.key(controller.account, widget.novelId)) ??
          'null',
    );
    if (mounted && progress is Map) {
      setState(() => _selected = progress['editionId'] as String?);
    }
    unawaited(controller.sync(widget.novelId, controller.account));
    await _refresh();
    if (!mounted || widget.initialChapterId == null) return;
    final ordered = [..._remote]
      ..sort(
        (a, b) => a['id'] == _selected
            ? -1
            : b['id'] == _selected
            ? 1
            : 0,
      );
    for (final book in ordered) {
      final chapter = (book['chapters'] as List)
          .where((c) => c['id'] == widget.initialChapterId && c['url'] != null)
          .firstOrNull;
      if (chapter != null) {
        _openPlayer(book, Map<String, dynamic>.from(chapter));
        return;
      }
    }
    setState(
      () => _error =
          'Chương đang đọc chưa có audio. Bạn có thể chọn giọng và gửi yêu cầu.',
    );
  }

  void _openPlayer(AudioJson book, AudioJson chapter) {
    unawaited(ref.read(audioBookControllerProvider).play(book, chapter));
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AudioBookPlayerScreen()));
  }

  bool _refreshing = false;
  Future<void> _refresh() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try {
      final dio = ref.read(apiClientProvider).dio;
      final results = await Future.wait([
        dio.get('/api/audiobooks/novels/${widget.novelId}'),
        dio.get('/api/audiobooks/voices'),
      ]);
      if (mounted) {
        setState(() {
          _novelTitle = results[0].data['title'] as String?;
          _remote = (results[0].data['editions'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _voices = (results[1].data['voices'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Không kết nối được máy chủ. Audio book cần kết nối mạng.',
        );
      }
    } finally {
      _refreshing = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    try {
      final result = await ref
          .read(apiClientProvider)
          .dio
          .post(
            '/api/audiobooks/novels/${widget.novelId}/requests',
            data: {'voiceId': _requestVoice},
          );
      if (!mounted) return;
      setState(() => _selected = result.data['id']);
      await _refresh();
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.response?.statusCode == 401
              ? 'Đăng nhập để yêu cầu Audio book.'
              : 'Không gửi được yêu cầu. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(audioBookControllerProvider);
    final editions = <String, AudioJson>{
      for (final e in _remote) e['id'] as String: e,
    };
    final selected =
        editions[_selected] ??
        (editions.isEmpty ? null : editions.values.first);
    final effective = selected;
    final chapters = (effective?['chapters'] as List? ?? [])
        .map((c) => Map<String, dynamic>.from(c))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio book'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: chapters.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected?['title'] ?? _novelTitle ?? 'Audio book',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nghe trực tuyến từng chương với giọng bạn chọn. Cần kết nối mạng để phát Audio book.',
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (_voices.isNotEmpty)
                          ExpansionTile(
                            title: const Text('Chọn giọng và gửi yêu cầu'),
                            tilePadding: EdgeInsets.zero,
                            children: [
                              Card(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.record_voice_over_outlined,
                                  ),
                                  title: Text(
                                    _voices
                                            .where(
                                              (v) => v['id'] == _requestVoice,
                                            )
                                            .firstOrNull?['name'] ??
                                        'Chọn giọng đọc',
                                  ),
                                  subtitle: Text(
                                    '${_voices.length} giọng · Chọn và nghe thử',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    final choice =
                                        await showModalBottomSheet<String>(
                                          context: context,
                                          isScrollControlled: true,
                                          showDragHandle: true,
                                          builder: (_) => SizedBox(
                                            height:
                                                MediaQuery.sizeOf(
                                                  context,
                                                ).height *
                                                .8,
                                            child: AudioBookVoicePicker(
                                              voices: _voices,
                                              selected: _requestVoice,
                                            ),
                                          ),
                                        );
                                    if (mounted && choice != null) {
                                      setState(() => _requestVoice = choice);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _requesting ? null : _request,
                                child: Text(
                                  _requesting
                                      ? 'Đang gửi…'
                                      : 'Yêu cầu tạo Audio book',
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: editions.values
                              .map(
                                (e) => ChoiceChip(
                                  label: Text(
                                    '${_voices.where((v) => v['id'] == e['voiceId']).firstOrNull?['name'] ?? e['voiceId']} · ${e['readyCount']}/${(e['chapters'] as List).length}',
                                  ),
                                  selected: selected?['id'] == e['id'],
                                  onSelected: (_) =>
                                      setState(() => _selected = e['id']),
                                ),
                              )
                              .toList(),
                        ),
                        if (editions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Chưa có Audio book. Chọn một giọng để yêu cầu tạo.',
                            ),
                          ),
                      ],
                    );
                  }
                  final c = chapters[index - 1];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        '${c['number']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(c['title'] ?? 'Chương ${c['number']}'),
                    subtitle: Text(
                      c['assetId'] != null
                          ? (c['hasUpdate'] == true
                                ? 'Đang tạo bản cập nhật'
                                : 'Có thể nghe')
                          : c['status'] == 'rendering'
                          ? 'Đang tạo'
                          : c['status'] == 'failed'
                          ? 'Tạo thất bại'
                          : 'Đang chờ',
                    ),
                    trailing: c['assetId'] != null
                        ? const Icon(Icons.play_circle_outline)
                        : const Icon(Icons.schedule),
                    onTap: c['assetId'] != null
                        ? () => _openPlayer(effective!, c)
                        : null,
                  );
                },
              ),
            ),
      bottomNavigationBar: controller.chapter == null
          ? null
          : SafeArea(
              child: Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.headphones),
                  title: Text(
                    'Chương ${controller.chapter!['number']} · ${controller.chapter!['title'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: const Text('Mở màn nghe'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AudioBookPlayerScreen(),
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: controller.player.playing ? 'Tạm dừng' : 'Phát',
                    onPressed: controller.loading ? null : controller.toggle,
                    icon: Icon(
                      controller.player.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
