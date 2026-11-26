import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_tokens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _websiteUrl = 'https://book-hunau.fmcoral.com';
  static const String _privacyUrl = 'https://book-hunau.fmcoral.com/privacy';

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打开链接失败')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打开链接失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/branding/app_icon_512.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppConstants.appName,
              style: AppText.pageTitle.copyWith(color: c.text),
            ),
            const SizedBox(height: AppSpacing.xs),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '';
                return Text(
                  'Version $version',
                  style: AppText.caption.copyWith(color: c.textMuted),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: AppRadius.cardAll,
                border: Border.all(color: c.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildTile(
                    context,
                    icon: Icons.public_rounded,
                    title: '软件官网',
                    onTap: () => _openUrl(context, _websiteUrl),
                  ),
                  Divider(height: 1, indent: 56, color: c.border),
                  _buildTile(
                    context,
                    icon: Icons.system_update_rounded,
                    title: '检查更新',
                    onTap: () => UpdateService.checkUpdate(
                      context,
                      showNoUpdate: true,
                    ),
                  ),
                  Divider(height: 1, indent: 56, color: c.border),
                  _buildTile(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: '隐私政策',
                    onTap: () => _openUrl(context, _privacyUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
              Icon(icon, size: 22, color: c.textMuted),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  title,
                  style: AppText.body.copyWith(color: c.text),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: c.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
