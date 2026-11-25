import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/course_model.dart';

/// 课表文件存储管理（仅保留核心查看所需的课程与第一周周一）。
class TimetableStorage {
  static const String coursesFileName = 'courses.json';
  static const String metaFileName = 'timetable_meta.json';

  Future<Directory> _directory() => getApplicationDocumentsDirectory();

  /// 读取本地课程列表；文件不存在或解析失败时返回空列表。
  Future<List<CourseModel>> readCourses() async {
    try {
      final file = File('${(await _directory()).path}/$coursesFileName');
      if (!await file.exists()) return [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((json) => CourseModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 保存课程列表（先写 .tmp 再原子替换）。
  Future<void> saveCourses(List<CourseModel> courses) async {
    final file = File('${(await _directory()).path}/$coursesFileName');
    final content = jsonEncode(courses.map((c) => c.toJson()).toList());
    await _atomicWrite(file, content);
  }

  /// 读取本学期第一周周一；不存在或解析失败时返回 null。
  Future<DateTime?> readFirstWeekMonday() async {
    try {
      final file = File('${(await _directory()).path}/$metaFileName');
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map && decoded['firstWeekMonday'] is String) {
        return DateTime.tryParse(decoded['firstWeekMonday'] as String);
      }
    } catch (_) {}
    return null;
  }

  /// 保存本学期第一周周一。
  Future<void> saveFirstWeekMonday(DateTime firstWeekMonday) async {
    final file = File('${(await _directory()).path}/$metaFileName');
    final content = jsonEncode({
      'firstWeekMonday': firstWeekMonday.toIso8601String(),
    });
    await _atomicWrite(file, content);
  }

  /// 按月份猜测开学周一（API 未返回日期时的兜底）。
  static DateTime guessFirstWeekMonday() {
    final now = DateTime.now();
    DateTime guess;
    if (now.month >= 8 || now.month <= 1) {
      guess = DateTime(now.month <= 1 ? now.year - 1 : now.year, 9, 1);
    } else {
      guess = DateTime(now.year, 2, 17);
    }
    while (guess.weekday != DateTime.monday) {
      guess = guess.add(const Duration(days: 1));
    }
    return guess;
  }

  /// 退出登录时清除本地课表，避免切换账号后仍显示上一个账号的数据。
  ///
  /// 同时清理同步备份文件，防止下一次同步失败时把旧账号课表还原回来。
  Future<void> clear() async {
    final dir = await _directory();
    for (final name in const [coursesFileName, metaFileName]) {
      for (final suffix in const ['', '.bak', '.tmp']) {
        final file = File('${dir.path}/$name$suffix');
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _atomicWrite(File file, String content) async {
    final tmpFile = File('${file.path}.tmp');
    try {
      await tmpFile.writeAsString(content, flush: true);
      try {
        await tmpFile.rename(file.path);
      } on FileSystemException {
        // Windows 上目标文件已存在时可能无法直接覆盖，退化为删除后重命名。
        if (await file.exists()) {
          await file.delete();
        }
        await tmpFile.rename(file.path);
      }
    } catch (_) {
      if (await tmpFile.exists()) {
        try {
          await tmpFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}

/// 同步前的文件备份：成功时删除 .bak，失败时原样回滚，保证旧课表不丢。
class TimetableBackup {
  static const List<String> _fileNames = [
    TimetableStorage.coursesFileName,
    TimetableStorage.metaFileName,
  ];
  static const String _extension = '.bak';

  final String baseDir;
  final Map<String, bool> existed;

  const TimetableBackup({
    required this.baseDir,
    required this.existed,
  });

  static Future<TimetableBackup> capture() async {
    final dir = await getApplicationDocumentsDirectory();
    final existed = <String, bool>{};
    for (final name in _fileNames) {
      final file = File('${dir.path}/$name');
      final bak = File('${dir.path}/$name$_extension');
      final exists = await file.exists();
      existed[name] = exists;
      if (exists) {
        try {
          await file.copy(bak.path);
        } catch (_) {}
      }
    }
    return TimetableBackup(baseDir: dir.path, existed: existed);
  }

  Future<void> restore() async {
    for (final name in _fileNames) {
      try {
        final file = File('$baseDir/$name');
        final bak = File('$baseDir/$name$_extension');
        if (existed[name] ?? false) {
          if (await bak.exists()) {
            await bak.copy(file.path);
          }
        } else if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> cleanup() async {
    for (final name in _fileNames) {
      try {
        final bak = File('$baseDir/$name$_extension');
        if (await bak.exists()) {
          await bak.delete();
        }
      } catch (_) {}
    }
  }
}
