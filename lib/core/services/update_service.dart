import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../utils/route_utils.dart';
import '../widgets/update_screen.dart';

/// 更新检查逻辑与牛×5 一致：
/// - 自动检查：发现新版本时底部 SnackBar 提示，点击「查看」进入更新页
/// - 手动检查（来自「关于」页）：有更新直接进入更新页，无更新/失败给出提示
class UpdateService {
  UpdateService._();

  static Future<void> checkUpdate(
    BuildContext context, {
    bool showNoUpdate = false,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      try {
        final response = await dio.get<Object?>(
          AppConstants.updateVersionUrl,
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to fetch version information');
        }

        final data = response.data;
        if (data is! Map) {
          throw Exception('Invalid version information');
        }
        final latestVersion = '${data['version'] ?? ''}'.trim();
        final releaseNotes = '${data['notes'] ?? ''}'.trim();
        if (latestVersion.isEmpty) {
          throw Exception('Invalid version information');
        }

        if (_isNewerVersion(latestVersion, currentVersion)) {
          if (!context.mounted) return;

          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text('🚀 发现新版本 v$latestVersion，点击查看详情'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: '查看',
                onPressed: () => Navigator.push(
                  context,
                  createSlideUpRoute(
                    UpdateScreen(
                      version: latestVersion,
                      releaseNotes: releaseNotes,
                      downloadUrl: AppConstants.updateDownloadUrl,
                    ),
                  ),
                ),
              ),
            ),
          );
          // 无障碍导航（读屏开启/关闭动画）时 SnackBar 不会自动消失，兜底 5 秒后关闭
          Future<void>.delayed(
            const Duration(seconds: 5),
            () => messenger.hideCurrentSnackBar(),
          );

          if (showNoUpdate) {
            Navigator.push(
              context,
              createSlideUpRoute(
                UpdateScreen(
                  version: latestVersion,
                  releaseNotes: releaseNotes,
                  downloadUrl: AppConstants.updateDownloadUrl,
                ),
              ),
            );
          }
        } else if (showNoUpdate && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已是最新版本')),
          );
        }
      } finally {
        dio.close(force: true);
      }
    } catch (e) {
      if (showNoUpdate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查更新失败: $e')),
        );
      }
    }
  }

  /// MVP 阶段直接打开下载地址；后续接入应用内下载与安装。
  static Future<void> startDownload(
    BuildContext context,
    String downloadUrl,
    String version,
  ) async {
    final uri = Uri.parse(downloadUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开 $uri')),
      );
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();

    for (var i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }
}
