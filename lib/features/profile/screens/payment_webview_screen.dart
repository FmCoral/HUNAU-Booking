import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_tokens.dart';

/// 支付承载页：加载支付宝表单或微信 H5 支付页。
///
/// `weixin://`、`alipays://` 等自定义 scheme 交给系统唤起对应 App；
/// 页面跳到支付成功地址时自动返回上一页。
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.title,
    this.html,
    this.url,
  }) : assert(html != null || url != null, 'html 与 url 至少提供一个');

  final String title;
  final String? html;
  final String? url;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  bool _loading = true;
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: '关闭',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.maybePop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialData: widget.html == null
                ? null
                : InAppWebViewInitialData(
                    data: widget.html!,
                    baseUrl: WebUri('https://fin-serv.hunau.edu.cn/'),
                  ),
            initialUrlRequest: widget.url == null
                ? null
                : URLRequest(url: WebUri(widget.url!)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              supportMultipleWindows: false,
              mediaPlaybackRequiresUserGesture: false,
            ),
            onLoadStart: (controller, url) {
              if (mounted) setState(() => _loading = true);
            },
            onLoadStop: (controller, url) {
              if (!mounted) return;
              setState(() => _loading = false);
              final href = url?.toString() ?? '';
              if (!_finished &&
                  (href.contains('paySuccess') || href.contains('pay/success'))) {
                _finished = true;
                Navigator.maybePop(context, true);
              }
            },
            onReceivedError: (controller, request, error) {
              if (mounted) setState(() => _loading = false);
            },
            shouldOverrideUrlLoading: (controller, action) async {
              final uri = action.request.url;
              if (uri == null) return NavigationActionPolicy.ALLOW;
              final scheme = uri.scheme.toLowerCase();
              if (scheme == 'http' ||
                  scheme == 'https' ||
                  scheme == 'about' ||
                  scheme == 'data') {
                return NavigationActionPolicy.ALLOW;
              }
              // weixin://、alipays://、intent:// 等交给系统 App
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {
                // 未安装对应 App 时保持当前页，用户可手动返回
              }
              return NavigationActionPolicy.CANCEL;
            },
          ),
          if (_loading)
            Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
