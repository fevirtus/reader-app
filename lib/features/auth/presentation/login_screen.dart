import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dang nhap')),
      body: const FeaturePlaceholder(
        title: 'Google Login',
        description:
            'Khung dang nhap Google OAuth cho mobile auth endpoint. Se bo sung token refresh va secure storage trong phase tiep theo.',
      ),
    );
  }
}
