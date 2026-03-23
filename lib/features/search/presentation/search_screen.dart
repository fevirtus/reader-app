import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tim kiem')),
      body: const FeaturePlaceholder(
        title: 'Search + Filters',
        description:
            'Khung tim kiem truyện voi goi y theo tu khoa, loc theo the loai/trang thai va sap xep theo views-rating-latest.',
      ),
    );
  }
}
