import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/route_utils.dart';
import '../services/campus_card_service.dart';
import 'payment_webview_screen.dart';

enum PaymentMethod { wechat, alipay }

/// 校园卡详情与充值页。
///
/// 顶部展示最新余额，下方选择金额并用微信 / 支付宝充值。
class CampusCardScreen extends StatefulWidget {
  const CampusCardScreen({super.key});

  @override
  State<CampusCardScreen> createState() => _CampusCardScreenState();
}

class _CampusCardScreenState extends State<CampusCardScreen>
    with WidgetsBindingObserver {
  final _logger = AppLogger.instance;

  static const List<double> _presetAmounts = [10, 20, 50];

  CampusCardInfo? _info;
  bool _loading = true;
  bool _refreshing = false;
  bool _paying = false;
  String? _error;
  double? _selectedAmount = 10;
  bool _customActive = false;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInfo();
    }
  }

  Future<void> _bootstrap() async {
    final cached = await CampusCardService.instance.loadCached();
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _info = cached;
        _loading = false;
      });
    }
    await _loadInfo();
  }

  Future<void> _loadInfo() async {
    if (!mounted) return;
    setState(() {
      if (_info == null) {
        _loading = true;
      } else {
        _refreshing = true;
      }
      _error = null;
    });

    try {
      final info = await CampusCardService.instance.refresh();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      _logger.w('Campus card refresh failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _selectPreset(double amount) {
    _amountController.clear();
    setState(() {
      _customActive = false;
      _selectedAmount = amount;
    });
  }

  void _onCustomAmountChanged(String raw) {
    final value = double.tryParse(raw);
    setState(() {
      _customActive = raw.trim().isNotEmpty;
      _selectedAmount = (value != null && value > 0) ? value : null;
    });
  }

  Future<void> _startRecharge(PaymentMethod method) async {
    if (_paying) return;

    final amount = _selectedAmount;
    if (amount == null) {
      _toast('请输入充值金额');
      return;
    }
    if (amount < 1 || amount > 1000) {
      _toast('充值金额需在 1–1000 元之间');
      return;
    }

    setState(() => _paying = true);
    try {
      final service = CampusCardService.instance;

      if (method == PaymentMethod.alipay) {
        final html = await service.getAlipayForm(amount.toDouble());
        if (!mounted) return;
        await Navigator.push(
          context,
          createSlideHorizontalRoute(
            PaymentWebViewScreen(title: '支付宝充值', html: html),
          ),
        );
      } else {
        final order = await service.createWeChatOrder(amount.toDouble());
        var launched = false;
        final deepLink = await service.getWeChatDeepLink(order.mwebUrl);
        if (deepLink != null) {
          try {
            launched = await launchUrl(
              Uri.parse(deepLink),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {
            launched = false;
          }
        }
        if (!launched) {
          if (!mounted) return;
          await Navigator.push(
            context,
            createSlideHorizontalRoute(
              PaymentWebViewScreen(title: '微信充值', url: order.mwebUrl),
            ),
          );
        }
      }

      if (!mounted) return;
      await _loadInfo();
    } catch (e) {
      _logger.e('Campus card recharge failed: $e');
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
    return Scaffold(
      appBar: AppBar(title: const Text('校园卡')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(context),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              '充值金额',
              style: AppText.bodyDense.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPresetGrid(context),
            const SizedBox(height: AppSpacing.md),
            _buildCustomAmountField(context),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: _buildPaymentBar(context),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final c = context.colors;
    final info = _info;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '当前余额',
                style: AppText.caption.copyWith(
                  color: c.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              InkWell(
                onTap: _refreshing ? null : _loadInfo,
                borderRadius: AppRadius.innerAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_refreshing)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      else
                        Icon(Icons.refresh, size: 14, color: c.textMuted),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _refreshing ? '刷新中' : '刷新',
                        style: AppText.caption.copyWith(color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            info != null && info.name.isNotEmpty
                ? '${info.name} (${info.idserial})'
                : '---',
            style: AppText.bodyDense.copyWith(
              color: c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading && info == null)
            Text('---', style: AppText.keyNumber.copyWith(color: c.text))
          else if (info != null)
            Text(
              '¥${info.balance}',
              style: AppText.keyNumber.copyWith(color: c.text),
            )
          else
            Text(
              _error ?? '获取余额失败',
              style: AppText.bodyDense.copyWith(color: c.danger),
            ),
        ],
      ),
    );
  }

  Widget _buildPresetGrid(BuildContext context) {
    final c = context.colors;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.4,
      ),
      itemCount: _presetAmounts.length,
      itemBuilder: (context, index) {
        final amount = _presetAmounts[index];
        final selected = !_customActive && _selectedAmount == amount;
        return InkWell(
          onTap: () => _selectPreset(amount),
          borderRadius: AppRadius.controlAll,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.statusBg(c.brand) : c.surface,
              borderRadius: AppRadius.controlAll,
              border: Border.all(color: selected ? c.brand : c.border),
            ),
            child: Text(
              '¥${amount.toStringAsFixed(0)}',
              style: AppText.bodyDense.copyWith(
                color: selected ? c.brandText : c.text,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomAmountField(BuildContext context) {
    final c = context.colors;

    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}(\.\d{0,2})?')),
      ],
      onChanged: _onCustomAmountChanged,
      style: AppText.bodyDense.copyWith(color: c.text),
      decoration: InputDecoration(
        hintText: '自定义金额（1–1000）',
        prefixText: '¥ ',
        isDense: true,
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: c.brand),
        ),
      ),
    );
  }

  Widget _buildPaymentBar(BuildContext context) {
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _paying
                        ? null
                        : () => _startRecharge(PaymentMethod.wechat),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF07C160),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF07C160),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
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
                            '微信充值',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _paying
                        ? null
                        : () => _startRecharge(PaymentMethod.alipay),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1677FF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1677FF),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.controlAll,
                      ),
                    ),
                    child: const Text(
                      '支付宝充值',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
