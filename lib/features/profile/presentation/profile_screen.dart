import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_names.dart';
import '../../../core/models/bookmark_model.dart';
import '../../../shared/widgets/main_app_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookshelf/providers/bookshelf_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final t = Theme.of(context);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final name = user == null
        ? 'Góc đọc của bạn'
        : (user.name?.trim().isNotEmpty == true
              ? user.name!.trim()
              : user.email);
    final books = user == null
        ? null
        : ref.watch(bookshelfProvider).valueOrNull;
    return Scaffold(
      body: Column(
        children: [
          const MainAppHeader(
            title: 'Cá nhân',
            subtitle: 'Một không gian đọc theo cách của bạn.',
            showSearch: false,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: t.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: t.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: t.colorScheme.primary.withAlpha(22),
                        foregroundColor: t.colorScheme.primary,
                        backgroundImage: user?.image != null
                            ? NetworkImage(user!.image!)
                            : null,
                        child: user?.image == null
                            ? const Icon(Icons.person_outline_rounded, size: 36)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: t.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user?.email ??
                            'Đăng nhập để lưu tủ sách và tiến độ đọc.',
                        textAlign: TextAlign.center,
                        style: t.textTheme.bodySmall?.copyWith(
                          color: t.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (user == null) ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: auth is AuthLoading
                              ? null
                              : () => context.push(RouteNames.login),
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: const Text('Đăng nhập bằng Google'),
                        ),
                      ],
                      if (books != null) ...[
                        const SizedBox(height: 22),
                        Divider(color: t.colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _Stat(
                              value: books
                                  .where(
                                    (b) => b.shelfStatus == ShelfStatus.reading,
                                  )
                                  .length,
                              label: 'Đang đọc',
                            ),
                            _Stat(
                              value: books.where((b) => b.isCompleted).length,
                              label: 'Đã đọc',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'TRẢI NGHIỆM ĐỌC',
                  style: t.textTheme.labelSmall?.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.tune_rounded,
                  title: 'Cài đặt đọc',
                  subtitle: 'Kiểu chữ, màu sắc và bố cục',
                  onTap: () => context.push(RouteNames.settings),
                ),
                _MenuTile(
                  icon: Icons.bookmarks_outlined,
                  title: 'Tủ sách của tôi',
                  subtitle: 'Đọc tiếp và quản lý truyện đã tải',
                  onTap: () => context.go(RouteNames.bookshelf),
                ),
                if (user != null) ...[
                  const SizedBox(height: 16),
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    title: 'Đăng xuất',
                    subtitle: 'Bản tải trên thiết bị vẫn được giữ lại',
                    onTap: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) context.go(RouteNames.home);
                    },
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  'VIRTUS READER',
                  textAlign: TextAlign.center,
                  style: t.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(icon, color: cs.primary),
          title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }
}
