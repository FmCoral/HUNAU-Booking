import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../services/update_service.dart';
import '../theme/app_tokens.dart';

/// 更新页。
///
/// - [UpdateScreen.check]：进入页面后立即检查，并在页面内展示检查中 / 失败 / 已是最新 / 有新版本；
/// - 默认构造：直接展示已知的新版本信息（启动自动检查的提示入口使用）。
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({
    super.key,
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
  }) : autoCheck = false;

  const UpdateScreen.check({super.key})
      : version = null,
        releaseNotes = null,
        downloadUrl = AppConstants.updateDownloadUrl,
        autoCheck = true;

  final String? version;
  final String? releaseNotes;
  final String downloadUrl;

  /// 是否进入页面后自动发起检查。
  final bool autoCheck;

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

enum _UpdateStatus { checking, failed, upToDate, available }

class _UpdateScreenState extends State<UpdateScreen> {
  _UpdateStatus _status = _UpdateStatus.checking;
  String? _version;
  String? _releaseNotes;
  String _currentVersion = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (widget.autoCheck) {
      _check();
    } else {
      _version = widget.version;
      _releaseNotes = widget.releaseNotes;
      _status = _UpdateStatus.available;
    }
  }

  Future<void> _check() async {
    setState(() {
      _status = _UpdateStatus.checking;
      _error = '';
    });

    try {
      final info = await UpdateService.fetchUpdate();
      if (!mounted) return;
      setState(() {
        _currentVersion = info.currentVersion;
        if (info.hasUpdate) {
          _version = info.latestVersion;
          _releaseNotes = info.releaseNotes;
          _status = _UpdateStatus.available;
        } else {
          _status = _UpdateStatus.upToDate;
        }
      });
    } on UpdateCheckException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _status = _UpdateStatus.failed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '检查更新失败，请检查网络后重试';
        _status = _UpdateStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.autoCheck
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text('检查更新'),
      ),
      body: switch (_status) {
        _UpdateStatus.checking => _buildChecking(),
        _UpdateStatus.failed => _buildResult(
            icon: Icons.cloud_off_rounded,
            iconColor: context.colors.textMuted,
            title: '检查更新失败',
            caption: _error,
          ),
        _UpdateStatus.upToDate => _buildResult(
            icon: Icons.check_circle_outline_rounded,
            iconColor: context.colors.brand,
            title: '已是最新版本',
            caption: _currentVersion.isEmpty
                ? null
                : 'Version $_currentVersion',
          ),
        _UpdateStatus.available => _buildAvailable(),
      },
    );
  }

  Widget _buildChecking() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '正在检查更新…',
            style: AppText.body.copyWith(color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildResult({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? caption,
  }) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: iconColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.keyNumber.copyWith(color: colors.text),
            ),
            if (caption != null && caption.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: colors.textMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: _check,
              child: const Text('重新检查'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailable() {
    final colors = context.colors;
    final version = _version ?? '';
    final releaseNotes = _releaseNotes ?? '';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.system_update_rounded,
                  size: 38,
                  color: colors.brand,
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  '发现新版本 v$version',
                  style: AppText.keyNumber.copyWith(color: colors.text),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  '更新日志',
                  style: AppText.sectionTitle.copyWith(color: colors.text),
                ),
                const SizedBox(height: AppSpacing.md),

                if (releaseNotes.isEmpty)
                  Text(
                    '暂无更新说明',
                    style: AppText.bodyDense.copyWith(color: colors.textMuted),
                  )
                else
                  MarkdownBody(
                    data: releaseNotes,
                    selectable: true,
                    shrinkWrap: true,
                    onTapLink: (text, href, title) async {
                      if (href != null) {
                        final uri = Uri.parse(href);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    },
                    styleSheet:
                        MarkdownStyleSheet.fromTheme(Theme.of(context))
                            .copyWith(
                              p: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: colors.text,
                              ),
                              h1: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.text,
                              ),
                              h2: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.text,
                              ),
                              h3: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.text,
                              ),
                              listBullet: TextStyle(
                                fontSize: 14,
                                color: colors.textMuted,
                              ),
                              a: TextStyle(
                                color: colors.brand,
                                decoration: TextDecoration.underline,
                              ),
                              code: TextStyle(
                                fontSize: 12.5,
                                backgroundColor: colors.surfaceSubtle,
                                color: colors.brand,
                                fontFamily: 'monospace',
                              ),
                            ),
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final route = ModalRoute.of(context);
                  await UpdateService.startDownload(
                    context,
                    widget.downloadUrl,
                    version,
                  );
                  if (route != null && nav.mounted) {
                    nav.removeRoute(route);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: 12,
                  ),
                ),
                child: const Text('立即更新'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
