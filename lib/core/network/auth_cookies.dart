import 'dart:io';

/// 内存中保存最近一次登录得到的 Cookie，供教务 WebView 注入使用。
class AuthCookies {
  AuthCookies._();

  static Map<Uri, List<Cookie>> _cookies = <Uri, List<Cookie>>{};

  static void save(Map<Uri, List<Cookie>> cookies) {
    _cookies = {
      for (final entry in cookies.entries)
        entry.key: List<Cookie>.from(entry.value),
    };
  }

  static Map<Uri, List<Cookie>> get all => _cookies;

  static void clear() {
    _cookies = <Uri, List<Cookie>>{};
  }
}
