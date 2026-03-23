import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class BookshelfScreen extends StatelessWidget {
  const BookshelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tu sach'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Dang doc'),
              Tab(text: 'Danh dau'),
              Tab(text: 'Da doc'),
              Tab(text: 'De cu'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FeaturePlaceholder(
              title: 'Dang doc',
              description: 'Danh sach truyện dang doc theo progress sync.',
            ),
            FeaturePlaceholder(
              title: 'Danh dau',
              description: 'Tat ca truyện da bookmark cua user.',
            ),
            FeaturePlaceholder(
              title: 'Da doc',
              description: 'Danh sach truyện da hoan thanh.',
            ),
            FeaturePlaceholder(
              title: 'De cu',
              description: 'Danh sach truyện user da de cu.',
            ),
          ],
        ),
      ),
    );
  }
}
