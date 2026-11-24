import 'package:flutter/foundation.dart';

/// 轻量日志工具：统一替代 package:logger，输出到 debugPrint。
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  void d(String message) => debugPrint(message);

  void i(String message) => debugPrint(message);

  void w(String message) => debugPrint(message);

  void e(String message) => debugPrint(message);
}
