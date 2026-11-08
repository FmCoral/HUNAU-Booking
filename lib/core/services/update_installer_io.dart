import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
import 'package:path_provider/path_provider.dart';

/// 清理历史下载的 APK，避免反复更新后堆积占空间。
Future<void> cleanOldApks({String? excludePath}) async {
  final dirs = <Directory>[];
  final extDir = await getExternalStorageDirectory();
  if (extDir != null) dirs.add(extDir);
  dirs.add(await getTemporaryDirectory());

  for (final dir in dirs) {
    if (!dir.existsSync()) continue;
    try {
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        if (!entity.path.toLowerCase().endsWith('.apk')) continue;
        if (excludePath != null && entity.path == excludePath) continue;
        try {
          entity.deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }
}

/// 返回 APK 的保存路径。
Future<String> prepareApkFilePath(String fileName) async {
  final dir = await getExternalStorageDirectory();
  if (dir == null) {
    throw Exception('外部存储不可用');
  }
  return '${dir.path}/$fileName';
}

/// 调起系统安装器安装 APK。
Future<void> installApkFile(String path) async {
  await AndroidPackageInstaller.installApk(apkFilePath: path);
}
