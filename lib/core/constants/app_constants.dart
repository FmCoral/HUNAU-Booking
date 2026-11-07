/// 全局常量
class AppConstants {
  const AppConstants._();

  /// 应用名称
  static const String appName = 'Book';

  // ---------- 更新与分发 ----------

  /// 版本信息（R2 公共桶）
  static const String updateVersionUrl =
      'https://apk.book.hunau.fmcoral.com/latest/version.json';

  /// APK 下载地址（R2 公共桶）
  static const String updateDownloadUrl =
      'https://apk.book.hunau.fmcoral.com/latest/app-release.apk';

  // ---------- 学校预约系统 ----------

  /// 超星场馆预约首页（reserveId 与 fidEnc 绑定学校机构）
  static const String gymReservationUrl =
      'https://reserve.chaoxing.com/front/web/apps/reservepc/index'
      '?reserveId=14191&fidEnc=a915b52ee0aa18ad';

  /// 每日开放时刻（08:00:00），释放次日的预约额度
  static const int openHour = 8;
}
