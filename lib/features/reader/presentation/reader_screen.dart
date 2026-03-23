import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  double fontSize = 18;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doc chuong ${widget.chapterId.isEmpty ? '?' : widget.chapterId}'),
        actions: [
          IconButton(
            onPressed: () => context.push(RouteNames.settings),
            icon: const Icon(Icons.tune),
            tooltip: 'Cai dat doc',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reader body placeholder with TOC, TTS, offline marker.'),
            const SizedBox(height: 12),
            Text('Co chu hien tai: ${fontSize.toStringAsFixed(0)}'),
            Slider(
              min: 14,
              max: 26,
              value: fontSize,
              onChanged: (v) => setState(() => fontSize = v),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Chuong truoc'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Chuong sau'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {},
        child: const Icon(Icons.record_voice_over),
      ),
    );
  }
}
