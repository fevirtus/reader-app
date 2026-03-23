import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../shared/widgets/feature_placeholder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tai khoan')),
      body: FeaturePlaceholder(
        title: 'User Profile',
        description:
            'Khung profile user, thong tin session, thong ke bookmark/de cu va cac cai dat doc dong bo.',
        actions: [
          FilledButton(
            onPressed: () => context.push(RouteNames.settings),
            child: const Text('Mo cai dat doc'),
          ),
        ],
      ),
    );
  }
}
