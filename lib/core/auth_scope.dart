import 'package:flutter/widgets.dart';

import 'auth_controller.dart';

/// 通过 InheritedNotifier 向下提供登录态。
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope 未挂载');
    return scope!.notifier!;
  }
}
