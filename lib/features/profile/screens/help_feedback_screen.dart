import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/auth_scope.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/feedback_reply_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/route_utils.dart';
import 'my_feedback_screen.dart';

/// 帮助与反馈，接口与布局与牛×5 一致。
class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      _toast('请输入内容');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = AuthScope.of(context).user;
      String version = '';
      try {
        version = (await PackageInfo.fromPlatform()).version;
      } catch (_) {}

      final payload = <String, dynamic>{
        'content': content,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'app': 'Book',
        'version': version,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      };
      final displayName = user?.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        payload['realName'] = displayName;
      }
      final username = user?.username;
      if (username != null && username.isNotEmpty) {
        payload['username'] = username;
      }

      final response = await Dio().post(
        AppConstants.feedbackEndpoint,
        data: payload,
      );

      if (!mounted) return;
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        if (username != null && username.isNotEmpty) {
          await FeedbackReplyService.markSubmitted(username);
        }
        if (!mounted) return;
        _controller.clear();
        _toast('提交成功');
      } else {
        _toast('提交失败 ($code)');
      }
    } catch (e) {
      if (!mounted) return;
      _toast('提交失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助与反馈'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              createSlideHorizontalRoute(const MyFeedbackScreen()),
            ),
            child: const Text('我的反馈'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '反馈内容',
              style: AppText.bodyDense.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _controller,
              maxLines: 8,
              maxLength: 1000,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: '请描述您遇到的问题或建议…',
                alignLabelWithHint: true,
              ),
            ),
            Text(
              '将附带相关信息用于调试',
              style: AppText.caption.copyWith(color: colors.textMuted),
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('提交'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
