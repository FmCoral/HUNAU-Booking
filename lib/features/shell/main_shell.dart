import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/glass/glass.dart';
import '../../core/services/update_service.dart';
import '../profile/profile_screen.dart';
import '../timetable/screens/timetable_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // 与牛×5 一致：进入主界面 3 秒后自动检查更新，失败静默。
    _updateTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      UpdateService.checkUpdate(context);
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 让页面内容延伸到悬浮玻璃底栏下方，玻璃才有东西可模糊。
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [TimetableScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: const [
          GlassNavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month,
            label: '课表',
          ),
          GlassNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: '我',
          ),
        ],
      ),
    );
  }
}
