import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';

class NovelDetailScreen extends StatelessWidget {
  const NovelDetailScreen({super.key, required this.novelId});

  final String novelId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiet truyện')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Novel ID: ${novelId.isEmpty ? '(missing)' : novelId}'),
          const SizedBox(height: 12),
          const Text(
            'Khung chi tiet truyện: metadata, series, chapter list, rating, bookmark, recommendation, comments.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: () => context.push('${RouteNames.reader}?chapterId=1'),
                child: const Text('Doc chuong 1'),
              ),
              OutlinedButton(
                onPressed: () =>
                    context.push('${RouteNames.comments}?novelId=$novelId'),
                child: const Text('Xem binh luan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
