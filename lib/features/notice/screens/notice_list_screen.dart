import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/route_utils.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';
import 'notice_detail_screen.dart';

/// 软件公告列表。
class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  List<Announcement> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await AnnouncementService.instance.fetch();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
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
      appBar: AppBar(title: const Text('公告')),
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
              ElevatedButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 72, color: c.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text('暂无公告', style: AppText.sectionTitle.copyWith(color: c.text)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '有新的消息时会显示在这里',
              style: AppText.caption.copyWith(color: c.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.page),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => _buildCard(context, _items[index]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Announcement item) {
    final c = context.colors;
    final icon = _iconFor(item.type, c);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          createSlideHorizontalRoute(NoticeDetailScreen(item: item)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.statusBg(icon.color),
                  borderRadius: AppRadius.innerAll,
                ),
                child: Icon(icon.icon, size: 20, color: icon.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppText.bodyDense.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.pinned) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '置顶',
                            style: AppText.caption.copyWith(
                              color: c.brandText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.content.replaceAll('\n', ' '),
                      style: AppText.caption.copyWith(color: c.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.publishedAt,
                      style: AppText.caption.copyWith(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
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

  ({IconData icon, Color color}) _iconFor(
    String type,
    AppSemanticColors c,
  ) {
    switch (type) {
      case 'feature':
        return (icon: Icons.auto_awesome_outlined, color: c.brand);
      case 'fix':
        return (icon: Icons.build_outlined, color: c.info);
      case 'warning':
        return (icon: Icons.warning_amber_outlined, color: c.warning);
      default:
        return (icon: Icons.campaign_outlined, color: c.brand);
    }
  }
}
