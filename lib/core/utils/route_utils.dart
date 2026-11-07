import 'package:flutter/material.dart';

/// 从下往上淡入的路由，与牛×5 的更新页、登录页一致。
Route<T> createSlideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.1);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      final offsetAnimation = animation.drive(
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve)),
      );
      final fadeAnimation = animation.drive(
        Tween<double>(begin: 0.0, end: 1.0),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

/// 从右往左滑入的路由，与牛×5 的二级页面一致。
Route<T> createSlideHorizontalRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.1, 0.0);
      const end = Offset.zero;
      final offsetAnimation = animation.drive(
        Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
      );
      return SlideTransition(position: offsetAnimation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
