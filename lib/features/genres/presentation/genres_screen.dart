import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class GenresScreen extends StatelessWidget {
  const GenresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The loai')),
      body: const FeaturePlaceholder(
        title: 'Genre Discovery',
        description:
            'Khung danh sach the loai va man hinh truyện theo the loai slug de dong bo hanh vi voi web.',
      ),
    );
  }
}
