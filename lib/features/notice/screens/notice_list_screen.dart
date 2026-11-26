import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/route_utils.dart';
import '../models/message_model.dart';
import '../services/notice_service.dart';
import 'notice_detail_screen.dart';

/// 公告列表，布局与牛×5 一致。
class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _readIds = <String>{};

  List<MessageModel> _messages = const [];
  String? _lastValue;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && !_loadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _refresh() async {
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await NoticeService.instance.fetchMessageList();
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _messages = result.messages;
        _lastValue = result.nextLastValue;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final result =
          await NoticeService.instance.fetchMessageList(lastValue: _lastValue);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, ...result.messages];
        _lastValue = result.nextLastValue;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _openDetail(MessageModel message) async {
    await Navigator.push(
      context,
      createSlideHorizontalRoute(
        NoticeDetailScreen(noticeId: message.idCode),
      ),
    );
    if (!mounted) return;
    setState(() => _readIds.add(message.idCode));
  }

  bool _isRead(MessageModel message) =>
      message.isRead || _readIds.contains(message.idCode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('公告')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = context.colors;

    if (_loading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: c.danger),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppText.bodyDense.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 72, color: c.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '暂无公告',
              style: AppText.sectionTitle.copyWith(color: c.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '有新的通知时会显示在这里',
              style: AppText.caption.copyWith(color: c.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: _messages.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          return _buildMessageCard(context, _messages[index]);
        },
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, MessageModel message) {
    final c = context.colors;
    final read = _isRead(message);

    String timeDisplay = message.sendTime;
    try {
      final parts = message.sendTime.split(' ');
      if (parts.length > 1) {
        final date = parts[0];
        final time = parts[1];
        final now = DateTime.now();
        final today =
            '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}';
        timeDisplay = (date == today) ? time.substring(0, 5) : date.substring(5);
      }
    } catch (_) {}

    final initial = message.createrName.isNotEmpty
        ? message.createrName[0]
        : '公';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(message),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: c.statusBg(c.brand),
                child: Text(
                  initial,
                  style: AppText.bodyDense.copyWith(
                    color: c.brandText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.createrName.isEmpty
                                ? '系统通知'
                                : message.createrName,
                            style: AppText.body.copyWith(
                              fontWeight:
                                  read ? FontWeight.w400 : FontWeight.w600,
                              color: read ? c.textMuted : c.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeDisplay,
                          style: AppText.caption.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.title,
                      style: AppText.bodyDense.copyWith(
                        color: read ? c.textMuted : c.text,
                        fontWeight: read ? FontWeight.w400 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      message.content
                          .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '')
                          .trim(),
                      style: AppText.caption.copyWith(color: c.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
