import 'package:flutter/material.dart';

import '../../../core/auth_scope.dart';
import '../../../core/services/feedback_reply_service.dart';
import '../../../core/theme/app_tokens.dart';

/// 我的反馈：展示当前学号提交过的反馈与回复。
class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({super.key});

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  List<FeedbackItem> _items = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final username = AuthScope.of(context).user?.username;
    if (username == null || username.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final items = await FeedbackReplyService.fetchAll(username);
    if (!mounted) return;

    if (items == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    final newest = items
        .where((e) => e.isReplied)
        .map((e) => e.repliedAt)
        .fold<String>('', (a, b) => a.compareTo(b) > 0 ? a : b);
    await FeedbackReplyService.markSeen(username, newest);

    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
      _failed = false;
    });
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的反馈')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_failed) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Center(
            child: Text(
              '加载失败',
              style: AppText.caption.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          Center(
            child: Text(
              '暂无反馈',
              style: AppText.caption.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.page),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = _items[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isReplied
                          ? colors.brandText
                          : colors.textMuted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    item.isReplied ? '已回复' : '待回复',
                    style: AppText.caption.copyWith(
                      color:
                          item.isReplied ? colors.brandText : colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(item.createdAt),
                    style: AppText.caption.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(item.content, style: AppText.bodyDense),
              if (item.isReplied) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.statusBg(colors.brand),
                    borderRadius: AppRadius.controlAll,
                  ),
                  child: Text(item.reply, style: AppText.bodyDense),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
