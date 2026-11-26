import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_logger.dart';
import '../models/electricity_model.dart';
import '../services/electricity_service.dart';

/// 宿舍电费充值：选择金额后用校园卡支付。
class DormRechargeScreen extends StatefulWidget {
  const DormRechargeScreen({
    super.key,
    required this.room,
    required this.slot,
  });

  final SavedElectricityRoom room;
  final int slot;

  @override
  State<DormRechargeScreen> createState() => _DormRechargeScreenState();
}

class _DormRechargeScreenState extends State<DormRechargeScreen>
    with WidgetsBindingObserver {
  final _logger = AppLogger.instance;

  static const List<double> _presetAmounts = [10, 20, 50, 100];

  ElectricityBalanceInfo? _balance;
  double? _selectedAmount = 10;
  bool _loading = true;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBalance();
    }
  }

  Future<void> _bootstrap() async {
    final cached = await ElectricityService.instance.loadCachedBalance(
      slot: widget.slot,
    );
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _balance = cached;
        _loading = false;
      });
    }
    await _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await ElectricityService.instance.getBalance(
        widget.room,
        slot: widget.slot,
      );
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _loading = false;
      });
    } catch (e) {
      _logger.w('Load dorm balance failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _recharge() async {
    final amount = _selectedAmount;
    if (amount == null || _paying) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认充值'),
        content: Text('使用校园卡支付 ¥${amount.toStringAsFixed(0)} 充值宿舍电费？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _paying = true);
    try {
      final success = await ElectricityService.instance.recharge(
        room: widget.room,
        amount: amount,
      );
      if (!mounted) return;
      if (!success) {
        _toast('充值失败，请稍后重试');
        return;
      }
      _toast('充值成功');
      electricityRevision.value++;
      await _loadBalance();
    } catch (e) {
      _logger.e('Dorm recharge failed: $e');
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final room = widget.room;

    return Scaffold(
      appBar: AppBar(title: const Text('宿舍电费')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.card),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: AppRadius.cardAll,
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前余额',
                    style: AppText.caption.copyWith(
                      color: c.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${room.areaName} ${room.buildingName} ${room.roomName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyDense.copyWith(
                      color: c.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _balance != null
                        ? '¥${_formatBalance(_balance!.balance)}'
                        : (_loading ? '...' : '¥--'),
                    style: AppText.keyNumber.copyWith(color: c.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              '充值金额',
              style: AppText.bodyDense.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 3.2,
              ),
              itemCount: _presetAmounts.length,
              itemBuilder: (context, index) {
                final amount = _presetAmounts[index];
                final selected = _selectedAmount == amount;
                return InkWell(
                  onTap: () => setState(() => _selectedAmount = amount),
                  borderRadius: AppRadius.controlAll,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? c.statusBg(c.brand) : c.surface,
                      borderRadius: AppRadius.controlAll,
                      border:
                          Border.all(color: selected ? c.brand : c.border),
                    ),
                    child: Text(
                      '¥${amount.toStringAsFixed(0)}',
                      style: AppText.bodyDense.copyWith(
                        color: selected ? c.brandText : c.text,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _paying ? null : _recharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: c.brand,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.controlAll,
                  ),
                ),
                child: _paying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '校园卡支付',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatBalance(String raw) {
    final value = double.tryParse(raw);
    return value != null ? value.toStringAsFixed(2) : raw;
  }
}
