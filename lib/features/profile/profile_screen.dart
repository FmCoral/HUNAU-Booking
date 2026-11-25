import 'package:flutter/material.dart';

import '../../core/auth_scope.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/route_utils.dart';
import 'screens/account_screen.dart';
import 'screens/campus_card_screen.dart';
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
  bool _retried = false;
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
      // 冷启动时静默重登可能还没写完 Cookie，自动补试一次。
      if (_info == null && !_retried) {
        _retried = true;
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_loading) _refresh();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openCampusCard() async {
    await Navigator.push(
      context,
      createSlideHorizontalRoute(const CampusCardScreen()),
    );
    if (mounted) await _refresh();
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
    final String balanceText;
    final String subtitle;

    if (info != null) {
      if (info.name.isNotEmpty && info.idserial.isNotEmpty) {
        subtitle = '${info.name} · ${info.idserial}';
      } else if (info.idserial.isNotEmpty) {
        subtitle = info.idserial;
      } else {
        subtitle = '校园卡';
      }
      balanceText = '¥${info.balance}';
    } else {
      subtitle = _error ?? (_loading ? '正在获取余额' : '点击查看');
      balanceText = _loading ? '...' : '¥--';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: c.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.cardAll,
        child: InkWell(
          borderRadius: AppRadius.cardAll,
          onTap: _openCampusCard,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.credit_card_outlined,
                  size: 22,
                  color: Color(0xFF1677FF),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '校园卡',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyDense.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                if (_loading && info != null)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.textMuted,
                    ),
                  )
                else
                  Text(
                    balanceText,
                    style: AppText.keyNumber.copyWith(
                      fontSize: 17,
                      color: c.text,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
