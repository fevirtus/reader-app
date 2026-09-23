import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_book_controller.dart';

String _voiceSearch(String value) {
  var text = value.toLowerCase();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    text = text.replaceAll(RegExp('[${entry.value}]'), entry.key);
  }
  return text;
}

class AudioBookVoicePicker extends ConsumerStatefulWidget {
  const AudioBookVoicePicker({
    super.key,
    required this.voices,
    required this.selected,
  });
  final List<AudioJson> voices;
  final String selected;
  @override
  ConsumerState<AudioBookVoicePicker> createState() =>
      _AudioBookVoicePickerState();
}

class _AudioBookVoicePickerState extends ConsumerState<AudioBookVoicePicker> {
  late String _selected = widget.selected;
  String _query = '';
  AudioBookController? _controller;

  @override
  void dispose() {
    if (_controller?.previewVoiceId != null) unawaited(_controller!.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(audioBookControllerProvider);
    _controller = controller;
    final filtered = widget.voices
        .where(
          (v) => _voiceSearch(
            '${v['name']} ${v['gender']} ${v['region']}',
          ).contains(_voiceSearch(_query)),
        )
        .toList();
    final selectedName =
        widget.voices.where((v) => v['id'] == _selected).firstOrNull?['name'] ??
        '';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: Column(
          children: [
            Text(
              'Chọn giọng đọc · ${widget.voices.length} giọng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Nghe cùng một đoạn mẫu để chọn giọng bạn thích.'),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm tên giọng, nam/nữ, vùng miền',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Không tìm thấy giọng phù hợp.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final v = filtered[i];
                        final previewing = controller.previewVoiceId == v['id'];
                        return ListTile(
                          selected: _selected == v['id'],
                          leading: Icon(
                            _selected == v['id']
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          title: Text(
                            '${v['name']}${v['default'] == true ? ' · Mặc định' : ''}',
                          ),
                          subtitle: Text(
                            '${v['gender']} · Miền ${v['region']}',
                          ),
                          onTap: () => setState(() => _selected = v['id']),
                          trailing: IconButton(
                            tooltip: v['previewUrl'] == null
                                ? 'Đang chuẩn bị mẫu'
                                : previewing
                                ? 'Dừng nghe thử ${v['name']}'
                                : 'Nghe thử ${v['name']}',
                            icon: previewing && controller.loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    previewing
                                        ? Icons.stop_circle_outlined
                                        : Icons.play_circle_outline,
                                  ),
                            onPressed: v['previewUrl'] == null
                                ? null
                                : () {
                                    setState(() => _selected = v['id']);
                                    unawaited(controller.previewVoice(v));
                                  },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: Text('Dùng giọng $selectedName'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
