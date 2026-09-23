import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/providers.dart';
import 'audio_book_controller.dart';
import 'audio_book_store.dart';

class AudioBookScreen extends ConsumerStatefulWidget {
  const AudioBookScreen({super.key, required this.novelId});
  final String novelId;
  @override
  ConsumerState<AudioBookScreen> createState() => _AudioBookScreenState();
}

class _AudioBookScreenState extends ConsumerState<AudioBookScreen> {
  List<AudioJson> _remote = [], _local = [], _voices = [];
  String? _selected, _error;
  String _requestVoice = 'anh-khoi';
  String? _novelTitle;
  bool _loading = true, _requesting = false;
  CancelToken? _download;
  int _done = 0, _total = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  Future<void> _load() async {
    final store = ref.read(audioBookStoreProvider);
    final local = await store.saved(novelId: widget.novelId);
    if (!mounted) return;
    setState(() {
      _local = local;
      _loading = local.isEmpty;
    });
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
              'Không kết nối được máy chủ. Các bản đã tải vẫn nghe được.',
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

  Future<void> _saveOffline(AudioJson edition) async {
    final cancel = CancelToken();
    setState(() {
      _download = cancel;
      _done = 0;
      _total = 0;
      _error = null;
    });
    try {
      await ref.read(audioBookStoreProvider).download(edition, cancel, (
        done,
        total,
      ) {
        if (mounted) {
          setState(() {
            _done = done;
            _total = total;
          });
        }
      });
      final local = await ref
          .read(audioBookStoreProvider)
          .saved(novelId: widget.novelId);
      if (mounted) setState(() => _local = local);
    } catch (e) {
      if (mounted && !cancel.isCancelled) {
        setState(
          () => _error =
              'Tải chưa hoàn tất. Bản cũ được giữ nguyên; bấm tải để tiếp tục.',
        );
      }
    } finally {
      if (mounted) setState(() => _download = null);
    }
  }

  Future<void> _delete(AudioJson edition) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Audio book offline?'),
        content: const Text(
          'Chỉ xóa audio của bản giọng này trên thiết bị. Văn bản truyện và bản trên máy chủ được giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final player = ref.read(audioBookControllerProvider);
    if (player.edition?['id'] == edition['id']) await player.stop();
    await ref.read(audioBookStoreProvider).delete(edition['id']);
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _download?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(audioBookControllerProvider);
    final editions = <String, AudioJson>{
      for (final e in _local) e['id'] as String: e,
      for (final e in _remote) e['id'] as String: e,
    };
    final selected =
        editions[_selected] ??
        (editions.isEmpty ? null : editions.values.first);
    AudioJson? saved;
    if (selected != null) {
      for (final e in _local) {
        if (e['id'] == selected['id']) saved = e;
      }
    }
    final hasUpdate =
        saved != null && saved['revision'] != selected?['revision'];
    // Keep the saved snapshot until the user explicitly downloads the update.
    final effective = saved ?? selected;
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
                          'Các bản giọng được tạo theo từng chương. Có thể nghe ngay khi chương hoàn tất.',
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
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _requestVoice,
                                  decoration: const InputDecoration(
                                    labelText: 'Giọng muốn nghe',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _voices
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v['id'] as String,
                                          child: Text(v['name']),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _requestVoice = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed: _requesting ? null : _request,
                                child: Text(
                                  _requesting ? 'Đang gửi…' : 'Yêu cầu tạo',
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
                        if (selected != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (_download == null)
                                  OutlinedButton.icon(
                                    onPressed:
                                        (selected['readyCount'] as num) > 0
                                        ? () => _saveOffline(selected)
                                        : null,
                                    icon: Icon(
                                      hasUpdate
                                          ? Icons.system_update_alt
                                          : Icons.download_for_offline_outlined,
                                    ),
                                    label: Text(
                                      hasUpdate
                                          ? 'Có bản cập nhật mới'
                                          : saved != null
                                          ? 'Tải lại / bổ sung'
                                          : 'Tải Audio book offline',
                                    ),
                                  ),
                                if (saved != null)
                                  IconButton(
                                    tooltip: 'Xóa bản tải trên máy',
                                    onPressed: _download == null
                                        ? () => _delete(saved!)
                                        : null,
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                              ],
                            ),
                          ),
                        if (_download != null)
                          Column(
                            children: [
                              LinearProgressIndicator(
                                value: _total > 0 ? _done / _total : null,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Đã tải $_done / $_total chương'),
                                  TextButton(
                                    onPressed: () => _download?.cancel(),
                                    child: const Text('Hủy'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        if (saved != null)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Đang dùng bản đã tải trên thiết bị',
                              style: TextStyle(fontSize: 12),
                            ),
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
                        ? () => controller.play(effective!, c)
                        : null,
                  );
                },
              ),
            ),
      bottomNavigationBar: controller.chapter == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chương ${controller.chapter!['number']} · ${controller.chapter!['title'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (controller.error != null)
                      Text(
                        controller.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    StreamBuilder<Duration>(
                      stream: controller.player.positionStream,
                      builder: (_, snapshot) {
                        final duration =
                            controller.player.duration?.inMilliseconds
                                .toDouble() ??
                            0;
                        final position = (snapshot.data?.inMilliseconds ?? 0)
                            .toDouble()
                            .clamp(0.0, duration);
                        return Slider(
                          value: position,
                          max: duration > 0 ? duration : 1,
                          onChanged: duration > 0
                              ? (v) => controller.player.seek(
                                  Duration(milliseconds: v.round()),
                                )
                              : null,
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Lùi 15 giây',
                          onPressed: () => controller.player.seek(
                            Duration(
                              milliseconds:
                                  (controller.player.position.inMilliseconds -
                                          15000)
                                      .clamp(0, 86400000),
                            ),
                          ),
                          icon: const Icon(Icons.replay_10),
                        ),
                        IconButton.filled(
                          tooltip: controller.player.playing
                              ? 'Tạm dừng'
                              : 'Phát',
                          onPressed: controller.loading
                              ? null
                              : controller.toggle,
                          icon: controller.loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  controller.player.playing
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<double>(
                          value: controller.player.speed,
                          items: [0.75, 1.0, 1.25, 1.5, 2.0]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v×'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) async {
                            await controller.player.setSpeed(v!);
                            if (mounted) setState(() {});
                          },
                        ),
                        IconButton(
                          tooltip: 'Dừng Audio book',
                          onPressed: controller.stop,
                          icon: const Icon(Icons.stop),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class AudioBookDownloadsScreen extends ConsumerStatefulWidget {
  const AudioBookDownloadsScreen({super.key});
  @override
  ConsumerState<AudioBookDownloadsScreen> createState() =>
      _AudioBookDownloadsState();
}

class _AudioBookDownloadsState extends ConsumerState<AudioBookDownloadsScreen> {
  late Future<List<AudioJson>> _items;
  @override
  void initState() {
    super.initState();
    _items = ref.read(audioBookStoreProvider).saved();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Audio book offline')),
    body: FutureBuilder<List<AudioJson>>(
      future: _items,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('Chưa tải Audio book nào.'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final e = items[i];
            return ListTile(
              leading: const Icon(Icons.headphones),
              title: Text(e['title']),
              subtitle: Text('${e['voiceId']} · ${e['readyCount']} chương'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => AudioBookScreen(novelId: e['novelId']),
                  ),
                );
                if (mounted) {
                  setState(
                    () => _items = ref.read(audioBookStoreProvider).saved(),
                  );
                }
              },
            );
          },
        );
      },
    ),
  );
}
