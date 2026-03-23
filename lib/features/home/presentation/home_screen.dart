import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../shared/widgets/feature_placeholder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chu')),
      body: FeaturePlaceholder(
        title: 'Home Feed',
        description:
            'Khung trang chu cho carousel hot, random grid, bang de cu, bang xep hang, truyện moi cap nhat va comments gan day.',
        actions: [
          FilledButton(
            onPressed: () => context.go(RouteNames.search),
            child: const Text('Mo tim kiem'),
          ),
        ],
      ),
    );
  }
}
