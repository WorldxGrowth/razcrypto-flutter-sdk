import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'options.dart';
import 'result.dart';

/// Opens RazCrypto checkout full screen and completes with a [CheckoutResult].
///
/// ```dart
/// final result = await RazCryptoCheckout.open(context, CheckoutOptions(key: 'pk_live_…', paymentId: id));
/// if (result is CheckoutSuccess) await api.verify(result); // then wait for the payment.paid webhook
/// ```
abstract final class RazCryptoCheckout {
  static const version = '1.0.0';

  static Future<CheckoutResult> open(BuildContext context, CheckoutOptions options) async {
    final r = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<CheckoutResult>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => CheckoutPage(options: options)));
    return r ?? const CheckoutCancelled();
  }
}

/// The checkout screen (use [RazCryptoCheckout.open], or push it yourself).
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.options});
  final CheckoutOptions options;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final WebViewController _web;
  CheckoutSuccess? _success;
  CheckoutPending? _pending;
  bool _loading = true;
  bool _done = false;

  String get _origin => widget.options.payOrigin;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('RazCryptoFlutter/${RazCryptoCheckout.version}')
      // The page calls window.RazCryptoNative.postMessage(json).
      ..addJavaScriptChannel('RazCryptoNative', onMessageReceived: (m) => unawaited(_onMessage(m.message)))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => mounted ? setState(() => _loading = false) : null,
          onWebResourceError: (e) {
            if (e.isForMainFrame == true && _success == null) _finish(CheckoutFailed('network_error', e.description));
          },
          // Stay in the WebView only for the pay origin; wallet links (MetaMask, Trust, wc:, …) open outside.
          onNavigationRequest: (req) {
            final uri = Uri.tryParse(req.url);
            if (uri == null) return NavigationDecision.prevent;
            if ((uri.scheme == 'https' || uri.scheme == 'http') && CheckoutOptions.originOf(uri) == _origin) return NavigationDecision.navigate;
            unawaited(launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false));
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(widget.options.embedUrl);
  }

  Future<void> _onMessage(String raw) async {
    // Only listen while the WebView shows the pay origin.
    final current = await _web.currentUrl();
    if (current == null || CheckoutOptions.originOf(Uri.parse(current)) != _origin) return;
    final m = BridgeMessage.parse(raw);
    if (m == null) return;
    switch (m.type) {
      case 'success':
        _success = m.toSuccess();
      case 'status':
        if (m.payload['status'] == 'confirming') _pending = CheckoutPending('${m.payload['payment_id'] ?? ''}');
      case 'done':
        _finish(_success ?? m.toSuccess());
      case 'close':
        _finish(_success ?? _pending ?? const CheckoutCancelled());
    }
  }

  void _finish(CheckoutResult r) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(r);
  }

  /// Back asks the page ("leave this payment?"); closes directly when the page is not ready.
  Future<void> _back() async {
    if (_success != null) return _finish(_success!);
    try {
      final r = await _web.runJavaScriptReturningResult(
        "(function(){if(window.__razcryptoRequestClose){window.__razcryptoRequestClose();return 'asked';}return 'none';})()",
      );
      if (!'$r'.contains('asked')) _finish(_pending ?? const CheckoutCancelled());
    } on Object {
      _finish(_pending ?? const CheckoutCancelled());
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_back());
    },
    child: Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _web),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    ),
  );
}
