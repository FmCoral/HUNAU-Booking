import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Book')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Card(
            child: InkWell(
              borderRadius: AppRadius.cardAll,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('功能开发中')),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.card),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.statusBg(c.brand),
                        borderRadius: AppRadius.innerAll,
                      ),
                      child: Icon(
                        Icons.sports_tennis,
                        size: 22,
                        color: c.brand,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '场馆预约',
                            style: AppText.sectionTitle.copyWith(color: c.text),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '乒乓球、羽毛球等体育场馆在线预约',
                            style: AppText.caption.copyWith(color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: c.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
