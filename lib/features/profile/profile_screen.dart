import 'package:flutter/material.dart';

import '../../core/auth_scope.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/route_utils.dart';
import 'screens/account_screen.dart';
import 'services/campus_card_service.dart';

/// 「我」页：顶部展示校园卡余额，其余留白；
/// 账号信息与设置在右上角设置入口内。
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  CampusCardInfo? _info;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 首帧后加载：先展示缓存，再静默刷新。
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final cached = await CampusCardService.instance.loadCached();
    if (!mounted) return;
    if (cached != null) {
      setState(() => _info = cached);
    }
    if (!AuthScope.of(context).isAuthenticated) return;
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await CampusCardService.instance.refresh();
      if (!mounted) return;
      setState(() => _info = info);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              tooltip: '设置',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                createSlideHorizontalRoute(const AccountScreen()),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            _buildBalanceCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final c = context.colors;
    final info = _info;
    final balance = info == null ? '--' : '¥ ${info.balance}';
    final subtitle = info != null
        ? '${info.name} · ${info.idserial}'
        : (_error ?? '正在获取校园卡余额');

    return Material(
      color: c.surface,
      borderRadius: AppRadius.cardAll,
      child: InkWell(
        onTap: _refresh,
        borderRadius: AppRadius.cardAll,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '校园卡余额',
                      style: AppText.caption.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      balance,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 32 / 26,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ).copyWith(color: c.text),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.textMuted,
                      ),
                    )
                  : Icon(Icons.refresh_rounded, size: 20, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
