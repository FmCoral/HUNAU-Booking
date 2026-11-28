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
///
/// 进入与返回共用一套位移：
/// - 新页面从右侧整屏滑入，返回时整屏滑出；
/// - 下层页面同步向左让位，返回时回到原位。
/// 之前只给新页面做了 10% 位移，返回时下层页面完全不动，
/// 上层页面几乎停在原地然后忽然消失，看起来会「不顺滑」。
Route<T> createSlideHorizontalRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;

      // 本页进出：0 -> 100% 右侧
      final enter = animation.drive(
        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: curve)),
      );

      // 有新页面压上来时，本页向左让位；返回时同步归位。
      final parallax = secondaryAnimation.drive(
        Tween(begin: Offset.zero, end: const Offset(-0.25, 0.0))
            .chain(CurveTween(curve: curve)),
      );

      return SlideTransition(
        position: parallax,
        child: SlideTransition(position: enter, child: child),
      );
    },
  );
}
