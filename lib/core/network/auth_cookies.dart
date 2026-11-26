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

  /// 拼出适用于 [uri] 的 Cookie 请求头。
  static String headerFor(Uri uri) {
    final values = <String>[];
    final seen = <String>{};
    for (final entry in _cookies.entries) {
      for (final cookie in entry.value) {
        final domain = cookie.domain;
        final matched = domain == null || domain.isEmpty
            ? entry.key.host == uri.host
            : uri.host == domain.replaceFirst(RegExp(r'^\.'), '') ||
                uri.host.endsWith(
                  domain.startsWith('.') ? domain : '.$domain',
                );
        if (!matched) continue;
        if (!seen.add(cookie.name)) continue;
        values.add('${cookie.name}=${cookie.value}');
      }
    }
    return values.join('; ');
  }

  static void clear() {
    _cookies = <Uri, List<Cookie>>{};
  }
}
