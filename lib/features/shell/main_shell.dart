import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/update_service.dart';
import '../../core/theme/app_tokens.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

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
    final c = context.colors;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (index) => setState(() => _index = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: '首页',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '我',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
