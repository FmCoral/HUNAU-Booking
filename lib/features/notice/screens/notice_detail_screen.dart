import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../services/notice_service.dart';

/// 公告详情，布局与牛×5 一致。
class NoticeDetailScreen extends StatefulWidget {
  const NoticeDetailScreen({super.key, required this.noticeId});

  final String noticeId;

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail =
          await NoticeService.instance.fetchNoticeDetail(widget.noticeId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      NoticeService.instance.setNoticeRead(widget.noticeId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('公告详情')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: c.danger),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppText.bodyDense.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Center(
        child: Text('公告不存在', style: AppText.bodyDense.copyWith(color: c.textMuted)),
      );
    }

    final title = detail['title']?.toString() ?? '无标题';
    final sender = detail['createrName']?.toString() ?? '系统';
    final time = detail['sendTime']?.toString() ?? '';
    final content = (detail['content']?.toString() ?? '').replaceAll('\r', '\n');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.pageTitle.copyWith(color: c.text),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: c.textMuted),
              const SizedBox(width: 6),
              Text(
                sender,
                style: AppText.caption.copyWith(
                  color: c.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: c.textMuted),
              const SizedBox(width: 6),
              Text(
                time,
                style: AppText.caption.copyWith(color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            content.trim(),
            style: AppText.body.copyWith(height: 1.7, color: c.text),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
