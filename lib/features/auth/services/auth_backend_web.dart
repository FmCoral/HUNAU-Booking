import 'dart:convert';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../models/auth_profile.dart';

const _bffBaseUrl = 'http://localhost:3000';

/// Web 端登录：请求本地 BFF，会话由 BFF 的 HttpOnly cookie 维护。
class BffAuthService {
  Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: _bffBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    )..httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
  }

  Future<AuthProfile> login(String username, String password) async {
    final dio = _createDio();
    try {
      final response = await dio.post<Object?>(
        '/api/login',
        data: {'username': username, 'password': password},
        options: Options(contentType: 'application/json'),
      );
      final body = _asMap(response.data);
      final status = response.statusCode ?? 0;
      if (status == 401) {
        throw AuthException(body['message']?.toString() ?? '账号或密码错误');
      }
      if (status != 200 || body['ok'] != true) {
        throw AuthException(body['message']?.toString() ?? '登录失败');
      }
      return _profileFrom(body, fallbackUsername: username) ??
          AuthProfile(username: username);
    } on DioException catch (error) {
      throw AuthException(_networkMessage(error));
    } finally {
      dio.close(force: true);
    }
  }

  Future<AuthProfile?> restore() async {
    final dio = _createDio();
    try {
      final response = await dio.get<Object?>('/api/me');
      if (response.statusCode != 200) return null;
      final body = _asMap(response.data);
      if (body['ok'] != true) return null;
      final username = '${body['username'] ?? ''}';
      if (username.isEmpty) return null;
      return _profileFrom(body, fallbackUsername: username);
    } catch (_) {
      return null;
    } finally {
      dio.close(force: true);
    }
  }

  Future<void> logout() async {
    final dio = _createDio();
    try {
      await dio.post<Object?>('/api/logout');
    } catch (_) {
      // 退出失败不阻塞本地清理。
    } finally {
      dio.close(force: true);
    }
  }

  static AuthProfile? _profileFrom(
    Map<String, dynamic> body, {
    required String fallbackUsername,
  }) {
    final profile = body['profile'];
    if (profile is Map) {
      final username = '${profile['username'] ?? ''}'.trim();
      final realName = '${profile['realName'] ?? ''}'.trim();
      return AuthProfile(
        username: username.isEmpty ? fallbackUsername : username,
        realName: realName.isEmpty ? null : realName,
      );
    }
    final username = '${body['username'] ?? ''}'.trim();
    return username.isEmpty ? null : AuthProfile(username: username);
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    }
    return const {};
  }

  static String _networkMessage(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      return 'Book BFF 返回异常状态，请检查终端日志';
    }
    return '未检测到 Book BFF，请先运行 bff/bin/server.dart';
  }
}
