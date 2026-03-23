import 'package:flutter/material.dart';

class CommentsScreen extends StatelessWidget {
  const CommentsScreen({
    super.key,
    required this.novelId,
    this.chapterId,
  });

  final String novelId;
  final String? chapterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Binh luan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Novel ID: ${novelId.isEmpty ? '(missing)' : novelId}'),
          Text('Chapter ID: ${chapterId ?? '(all novel comments)'}'),
          const SizedBox(height: 12),
          const Text('Khung danh sach binh luan + form gui comment + phan trang.'),
          const SizedBox(height: 20),
          TextField(
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Viet binh luan cua ban...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {},
            child: const Text('Gui binh luan'),
          ),
        ],
      ),
    );
  }
}
