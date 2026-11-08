import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../utils/route_utils.dart';
import '../widgets/update_screen.dart';
import 'update_installer.dart';

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

  /// 应用内下载 APK 并调起系统安装器；Web 端回退到浏览器下载。
  static Future<void> startDownload(
    BuildContext context,
    String downloadUrl,
    String version,
  ) async {
    if (kIsWeb) {
      final uri = Uri.parse(downloadUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开 $uri')),
        );
      }
      return;
    }

    await cleanOldApks();

    if (!context.mounted) return;

    final String savePath;
    try {
      savePath = await prepareApkFilePath('app_v$version.apk');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
      return;
    }

    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DownloadProgressDialog(
        url: downloadUrl,
        savePath: savePath,
        onCompleted: (path) async {
          if (dialogContext.mounted) Navigator.pop(dialogContext);
          try {
            await installApkFile(path);
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('安装失败，请检查「安装未知应用」权限: $e'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
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

/// 下载进度弹窗：显示百分比与已下载/总大小，可取消。
class _DownloadProgressDialog extends StatefulWidget {
  const _DownloadProgressDialog({
    required this.url,
    required this.savePath,
    required this.onCompleted,
  });

  final String url;
  final String savePath;
  final ValueChanged<String> onCompleted;

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  final Dio _dio = Dio();
  CancelToken? _token;
  double _progress = 0;
  int _received = 0;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _download();
  }

  @override
  void dispose() {
    _token?.cancel();
    _dio.close(force: true);
    super.dispose();
  }

  Future<void> _download() async {
    _token = CancelToken();
    try {
      await _dio.download(
        widget.url,
        widget.savePath,
        cancelToken: _token,
        onReceiveProgress: (count, total) {
          if (!mounted) return;
          setState(() {
            _received = count;
            _total = total > 0 ? total : 0;
            _progress = total > 0 ? count / total : 0;
          });
        },
      );
      if (!mounted) return;
      widget.onCompleted(widget.savePath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is DioException && CancelToken.isCancel(e)
            ? '已取消下载'
            : e.toString();
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var index = 0;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(index == 0 ? 0 : 1)} ${units[index]}';
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;

    return AlertDialog(
      title: Text(error == null ? '正在下载更新' : '下载失败'),
      content: error != null
          ? Text(error)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: _total > 0 ? _progress : null,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(_progress * 100).toStringAsFixed(0)}%'),
                    Text(
                      _total > 0
                          ? '${_formatSize(_received)} / ${_formatSize(_total)}'
                          : _formatSize(_received),
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () {
            _token?.cancel();
            Navigator.pop(context);
          },
          child: Text(error == null ? '取消' : '关闭'),
        ),
      ],
    );
  }
}
