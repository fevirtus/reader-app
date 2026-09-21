import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthAuthenticated) {
        context.go(RouteNames.home);
      }
    });

    final isLoading = authState is AuthLoading;
    final errorMsg = authState is AuthError ? authState.message : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    'Mang câu chuyện theo bạn',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lưu tủ sách, đọc tiếp trên mọi thiết bị và tìm những câu chuyện bạn yêu thích.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (errorMsg != null) ...[
                    Text(errorMsg, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                  ],
                  if (authState is AuthLoading) ...[
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 12),
                    const Text('Đang mở Google Sign-In...'),
                    const SizedBox(height: 20),
                  ],
                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => ref
                              .read(authProvider.notifier)
                              .signInWithGoogle(),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Đăng nhập bằng Google'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go(RouteNames.home),
                    child: const Text('Khám phá trước, đăng nhập sau'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
