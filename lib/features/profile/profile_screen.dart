import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/route_utils.dart';
import 'screens/account_screen.dart';

/// 「我」页：默认保持空白，所有账号信息与设置在右上角入口内。
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              tooltip: '设置',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                createSlideHorizontalRoute(const AccountScreen()),
              ),
            ),
          ),
        ],
      ),
      body: const SizedBox.shrink(),
    );
  }
}
