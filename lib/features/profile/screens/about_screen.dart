import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_tokens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
              child: InkWell(
                onTap: () => UpdateService.checkUpdate(
                  context,
                  showNoUpdate: true,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.system_update_rounded,
                          size: 22,
                          color: c.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Text(
                            '检查更新',
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
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
