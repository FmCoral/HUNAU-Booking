import 'package:flutter/foundation.dart';

/// 课表数据变更信号。
///
/// 任何入口（设置页手动同步等）写入课表文件后自增，
/// 课表页监听该值重新读取本地文件，避免停留在旧数据。
final ValueNotifier<int> timetableRevision = ValueNotifier<int>(0);
