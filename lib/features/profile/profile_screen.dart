import 'package:flutter/material.dart';

import '../../core/auth_controller.dart';
import '../../core/auth_scope.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/route_utils.dart';
import 'screens/about_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Column(
          children: [
            _buildUserInfo(context, user?.displayName ?? '', user?.username ?? ''),

            const SizedBox(height: AppSpacing.xxl),

            // 功能入口卡片（暂未接入，先预留）
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: AppRadius.cardAll,
                border: Border.all(color: c.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.settings_outlined,
                    title: '设置',
                  ),
                  Divider(height: 1, indent: 56, color: c.border),
                  _buildListTile(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: '帮助与反馈',
                  ),
                  Divider(height: 1, indent: 56, color: c.border),
                  _buildListTile(
                    context,
                    icon: Icons.rocket_launch_outlined,
                    title: '开始引导',
                  ),
                  Divider(height: 1, indent: 56, color: c.border),
                  _buildListTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: '关于',
                    onTap: () => Navigator.push(
                      context,
                      createSlideHorizontalRoute(const AboutScreen()),
                    ),
                  ),
                ],
              ),
            ),

            // 退出登录（危险操作，独立卡片）
            if (user != null || auth.isAuthenticating) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: AppRadius.cardAll,
                  border: Border.all(color: c.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildListTile(
                  context,
                  icon: Icons.logout_rounded,
                  title: '退出登录',
                  titleColor:
                      auth.isAuthenticating ? c.textMuted : c.danger,
                  iconColor: auth.isAuthenticating ? c.textMuted : c.danger,
                  onTap:
                      auth.isAuthenticating
                          ? null
                          : () => _handleLogout(context, auth),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(
    BuildContext context,
    String displayName,
    String username,
  ) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xl,
      ),
      width: double.infinity,
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: c.surfaceSubtle,
            child: Icon(
              Icons.person_rounded,
              size: 36,
              color: c.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppText.pageTitle.copyWith(color: c.text),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  username,
                  style: AppText.caption.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? c.textMuted),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  title,
                  style: AppText.body.copyWith(
                    color: titleColor ?? c.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthController auth) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出登录后将清除您的本地凭证并断开数据连接。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await auth.logout();
    }
  }
}
