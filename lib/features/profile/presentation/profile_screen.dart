import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../shared/widgets/main_app_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookshelf/providers/bookshelf_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final bookshelfAsync = ref.watch(bookshelfProvider);
    final bookmarkedCount =
        bookshelfAsync.maybeWhen(data: (items) => items.length, orElse: () => 0);
    final displayName = authState is AuthAuthenticated
      ? ((authState.user.name != null && authState.user.name!.trim().isNotEmpty)
        ? authState.user.name!.trim()
        : authState.user.email)
      : '';

    return Scaffold(
      body: Column(
        children: [
          const MainAppHeader(title: 'Trang cá nhân', showGenresShortcut: false),
          Expanded(
            child: switch (authState) {
              AuthAuthenticated(:final user) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundImage:
                                  user.image != null ? NetworkImage(user.image!) : null,
                              child: user.image == null
                                  ? Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  Text(
                                    user.role.toLowerCase(),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  _AccountStatRow(
                                    icon: Icons.auto_awesome,
                                    label: 'Tiên Thạch: 0.00 TT',
                                  ),
                                  const SizedBox(height: 4),
                                  _AccountStatRow(
                                    icon: Icons.diamond,
                                    label: 'Linh Phiếu: 0 LP',
                                  ),
                                  const SizedBox(height: 4),
                                  _AccountStatRow(
                                    icon: Icons.local_activity,
                                    label: 'Ngọc Phiếu: $bookmarkedCount',
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.workspace_premium_rounded),
                                    label: const Text('Thêm Tiên Thạch'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF14B8A6),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ProfileMenuTile(
                        title: 'Chỉnh sửa thông tin',
                        onTap: () => context.push(RouteNames.settings),
                      ),
                      _ProfileMenuTile(
                        title: 'Lịch sử giao dịch',
                        onTap: () {},
                      ),
                      _ProfileMenuTile(
                        title: 'Liên hệ, báo lỗi',
                        onTap: () {},
                      ),
                      _ProfileMenuTile(
                        title: 'Điều khoản dịch vụ',
                        onTap: () {},
                      ),
                      _ProfileMenuTile(
                        title: 'Xóa tài khoản',
                        onTap: () {},
                      ),
                      _ProfileMenuTile(
                        title: 'Đăng xuất',
                        onTap: () async {
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) context.go(RouteNames.home);
                        },
                      ),
                    ],
                  ),
                ),
              AuthError(:final message) => Center(child: Text(message)),
              AuthUnauthenticated() => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                          child: const Text('Đăng nhập bằng Google'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.push(RouteNames.settings),
                          icon: const Icon(Icons.tune),
                          label: const Text('Mở Cài Đặt Đọc'),
                        ),
                      ],
                    ),
                  ),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _AccountStatRow extends StatelessWidget {
  const _AccountStatRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF58D68D)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
