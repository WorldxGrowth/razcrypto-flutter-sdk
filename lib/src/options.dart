/// What to open. Use a publishable key + payment id (created on your server), or the payment's `checkout_url`.
/// Never put a secret key (`sk_…`) in an app.
class CheckoutOptions {
  /// Publishable key + payment id.
  CheckoutOptions({required String key, required String paymentId, this.payHost = defaultPayHost, this.locale})
    : key = key,
      paymentId = paymentId,
      checkoutUrl = null {
    _validateKey(key, paymentId, payHost);
  }

  /// The `checkout_url` your server received when it created the payment.
  CheckoutOptions.fromCheckoutUrl(String url, {this.locale}) : key = null, paymentId = null, checkoutUrl = url, payHost = defaultPayHost {
    _validateUrl(url);
  }

  static const defaultPayHost = 'https://pay.razcryptogateway.com';
  static final _payId = RegExp(r'^pay_[0-9A-Za-z]{20}$');
  static final _pk = RegExp(r'^pk_(live|test)_[0-9A-Za-z]{16,}$');

  final String? key;
  final String? paymentId;
  final String? checkoutUrl;
  final String payHost;

  /// `en` or `hi`; default: the page's own choice.
  final String? locale;

  static bool _local(String host) => host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';

  static void _validateKey(String key, String paymentId, String payHost) {
    if (key.startsWith('sk_')) throw ArgumentError('Never use a secret key in an app. Pass your publishable key (pk_…).');
    if (!_pk.hasMatch(key)) throw ArgumentError('key must be a publishable key (pk_live_… or pk_test_…)');
    if (!_payId.hasMatch(paymentId)) throw ArgumentError('paymentId must look like pay_…');
    final u = Uri.tryParse(payHost);
    if (u == null || !(u.scheme == 'https' || (u.scheme == 'http' && _local(u.host)))) throw ArgumentError('payHost must be https');
  }

  static void _validateUrl(String url) {
    final u = Uri.tryParse(url);
    if (u == null || !(u.scheme == 'https' || (u.scheme == 'http' && _local(u.host)))) throw ArgumentError('checkout_url must be an https URL');
    final id = u.pathSegments.isEmpty ? '' : u.pathSegments.last;
    if (!_payId.hasMatch(id) || (u.queryParameters['t'] ?? '').isEmpty) {
      throw ArgumentError('checkout_url must be the URL returned when the payment was created');
    }
  }

  /// Embedded checkout page the WebView loads.
  Uri get embedUrl {
    if (checkoutUrl != null) {
      final u = Uri.parse(checkoutUrl!);
      return u.replace(pathSegments: ['embed', u.pathSegments.last], queryParameters: {'t': u.queryParameters['t']!, 'locale': ?locale});
    }
    final base = Uri.parse(payHost);
    return base.replace(
      pathSegments: [...base.pathSegments.where((s) => s.isNotEmpty), 'embed', paymentId!],
      queryParameters: {'key': key!, 'locale': ?locale},
    );
  }

  /// Origin the checkout is served from; only this origin may talk to the app.
  String get payOrigin => originOf(checkoutUrl != null ? Uri.parse(checkoutUrl!) : Uri.parse(payHost));

  static String originOf(Uri u) => '${u.scheme}://${u.host}${u.hasPort && u.port != 80 && u.port != 443 ? ':${u.port}' : ''}';
}
