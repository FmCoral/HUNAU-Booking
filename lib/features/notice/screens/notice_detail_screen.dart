import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_tokens.dart';
import '../models/announcement.dart';

/// 公告详情。
class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key, required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasLink =
        (item.linkUrl ?? '').isNotEmpty && (item.linkText ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('公告详情')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: AppText.pageTitle.copyWith(color: c.text),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: c.textMuted),
                const SizedBox(width: 6),
                Text(
                  item.publishedAt,
                  style: AppText.caption.copyWith(color: c.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              item.content.trim(),
              style: AppText.body.copyWith(height: 1.7, color: c.text),
            ),
            if (hasLink) ...[
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: () => launchUrl(
                  Uri.parse(item.linkUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(item.linkText!),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
