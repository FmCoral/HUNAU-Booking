import 'package:flutter/material.dart';

import '../../core/auth_scope.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/route_utils.dart';
import 'screens/account_screen.dart';
import 'screens/campus_card_screen.dart';
import 'screens/dorm_recharge_screen.dart';
import 'models/electricity_model.dart';
import 'services/campus_card_service.dart';
import 'services/electricity_service.dart';

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

  final List<SavedElectricityRoom?> _dorms = [null, null];
  final List<ElectricityBalanceInfo?> _eleBalances = [null, null];
  bool _eleLoading = false;

  @override
  void initState() {
    super.initState();
    electricityRevision.addListener(_loadElectricity);
    // 首帧后加载：先展示缓存，再静默刷新。
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    electricityRevision.removeListener(_loadElectricity);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cached = await CampusCardService.instance.loadCached();
    if (!mounted) return;
    if (cached != null) {
      setState(() => _info = cached);
    }
    await _loadElectricity();
    if (!mounted) return;
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

  Future<void> _openDormRecharge(int slot, SavedElectricityRoom room) async {
    await Navigator.push(
      context,
      createSlideHorizontalRoute(
        DormRechargeScreen(room: room, slot: slot),
      ),
    );
    await _loadElectricity();
  }

  Future<void> _loadElectricity() async {
    if (_eleLoading) return;

    final rooms = <SavedElectricityRoom?>[];
    final cachedBalances = <ElectricityBalanceInfo?>[];
    for (var slot = 0; slot < _dorms.length; slot++) {
      rooms.add(await ElectricityService.instance.loadSavedRoom(slot: slot));
      cachedBalances.add(
        await ElectricityService.instance.loadCachedBalance(slot: slot),
      );
    }
    if (!mounted) return;

    setState(() {
      for (var slot = 0; slot < _dorms.length; slot++) {
        _dorms[slot] = rooms[slot];
        if (cachedBalances[slot] != null) {
          _eleBalances[slot] = cachedBalances[slot];
        }
        if (rooms[slot] == null) {
          _eleBalances[slot] = null;
        }
      }
      _eleLoading = true;
    });

    if (!AuthScope.of(context).isAuthenticated) {
      if (mounted) setState(() => _eleLoading = false);
      return;
    }

    for (var slot = 0; slot < _dorms.length; slot++) {
      final room = rooms[slot];
      if (room == null) continue;
      try {
        final balance = await ElectricityService.instance.getBalance(
          room,
          slot: slot,
        );
        if (!mounted) return;
        setState(() => _eleBalances[slot] = balance);
      } catch (_) {
        // 保持缓存值，失败静默
      }
    }
    if (mounted) setState(() => _eleLoading = false);
  }

  String _formatElectricityBalance(String raw) {
    final value = double.tryParse(raw);
    return value != null ? value.toStringAsFixed(2) : raw;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              '余额',
              style: AppText.sectionTitle.copyWith(color: context.colors.text),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildBalanceCard(context),
            const SizedBox(height: AppSpacing.md),
            _buildElectricityCard(context),
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

  Widget _buildElectricityCard(BuildContext context) {
    final c = context.colors;
    final entries = <({int slot, SavedElectricityRoom room})>[
      for (var slot = 0; slot < _dorms.length; slot++)
        if (_dorms[slot] != null) (slot: slot, room: _dorms[slot]!),
    ];

    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.bolt_outlined,
              size: 22,
              color: Color(0xFFFF9800),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '宿舍电费',
                    style: AppText.bodyDense.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '未选择宿舍',
                    style: AppText.caption.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '设置 · 通用设置 · 宿舍配置',
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
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_outlined,
            size: 22,
            color: Color(0xFFFF9800),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _buildDormRow(context, entries[i].slot, entries[i].room),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDormRow(
    BuildContext context,
    int slot,
    SavedElectricityRoom room,
  ) {
    final c = context.colors;
    final balance = _eleBalances[slot];
    final roomName = room.roomName.isNotEmpty ? room.roomName : room.roomId;
    final subtitle = room.buildingName.isEmpty
        ? roomName
        : (room.buildingName.endsWith(roomName)
            ? room.buildingName
            : '${room.buildingName} $roomName');
    final balanceText = balance != null
        ? '¥${_formatElectricityBalance(balance.balance)}'
        : (_eleLoading ? '...' : '¥--');
    var balanceColor = c.text;
    final value = balance != null ? double.tryParse(balance.balance) : null;
    if (value != null && value <= 10) balanceColor = c.danger;

    return InkWell(
      borderRadius: AppRadius.innerAll,
      onTap: () => _openDormRecharge(slot, room),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.areaName.isNotEmpty ? room.areaName : '宿舍电费',
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
            Text(
              balanceText,
              style: AppText.keyNumber.copyWith(
                fontSize: 17,
                color: balanceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
