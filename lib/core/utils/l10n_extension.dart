import 'package:flutter/widgets.dart';

extension AppL10nX on BuildContext {
  /// 便捷获取中文文案，例如 context.l10n.noLocalTimetable
  AppL10n get l10n => const AppL10n();
}

/// 课表模块使用的中文文案（与 hunau 的 app_zh.arb 保持一致）。
class AppL10n {
  const AppL10n();

  String get noLocalTimetable => '暂无本地课表';
  String get tapRefreshButtonToSync => '点击右上角刷新按钮手动同步';
  String get timetableSyncing => '课表正在同步中';
  String get timetableSyncingDesc => '系统正在为您全自动拉取教务课表\n请稍等片刻...';
  String get noTimetableFound => '未获取到课表';

  String get weekdayMon => '周一';
  String get weekdayTue => '周二';
  String get weekdayWed => '周三';
  String get weekdayThu => '周四';
  String get weekdayFri => '周五';
  String get weekdaySat => '周六';
  String get weekdaySun => '周日';

  String get month1 => '一月';
  String get month2 => '二月';
  String get month3 => '三月';
  String get month4 => '四月';
  String get month5 => '五月';
  String get month6 => '六月';
  String get month7 => '七月';
  String get month8 => '八月';
  String get month9 => '九月';
  String get month10 => '十月';
  String get month11 => '十一月';
  String get month12 => '十二月';

  String get teacher => '教师';
  String get classroom => '教室';
  String get weeksLabel => '周次';
  String get periodsLabel => '节次';
  String get timeLabel => '时间';
  String get changeColor => '修改颜色';
  String get selectCourseColor => '选择课程颜色';
  String get close => '关闭';
  String get unknown => '未知';

  String weekNumber(int week) => '第$week周';

  String weeksRange(String weeks) => '第$weeks周';

  String periodsRange(int start, int end) => '第$start-$end节';

  String colorSwappedNotice(String course) => '已与「$course」互换课程颜色';
}
