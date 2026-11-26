import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../network/auth_cookies.dart';

/// 头像下载：photo.chaoxing.com 在未登录时会 302 到登录页，
/// 必须携带登录 Cookie 取图并缓存到本地，与牛×5 一致。
class AvatarService {
  AvatarService._();

  static final AvatarService instance = AvatarService._();

  Future<String?> fetchToFile(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/avatar_$uid.png');
      if (await file.exists() && await file.length() > 0) {
        return file.path;
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      var uri = Uri.parse(AppConstants.fusionAvatarUrl(uid));
      for (var redirect = 0; redirect < 5; redirect++) {
        final response = await dio.get<List<int>>(
          uri.toString(),
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) => status != null && status < 500,
            headers: {
              'User-Agent': AppConstants.campusCardUA,
              'Cookie': AuthCookies.headerFor(uri),
            },
          ),
        );

        if (const [301, 302, 303, 307, 308]
            .contains(response.statusCode)) {
          final location =
              response.headers.value(HttpHeaders.locationHeader);
          if (location == null) return null;
          final next = uri.resolve(location);
          if (next.scheme != 'https' ||
              next.path.contains('/cas/login') ||
              next.host.startsWith('passport')) {
            return null;
          }
          uri = next;
          continue;
        }

        final type =
            response.headers.value(HttpHeaders.contentTypeHeader) ?? '';
        final bytes = response.data;
        if (response.statusCode != 200 ||
            !type.toLowerCase().startsWith('image/') ||
            bytes == null ||
            bytes.isEmpty) {
          return null;
        }
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      }
    } catch (_) {
      // 头像失败不阻断登录
    }
    return null;
  }
}
