import 'package:flutter_test/flutter_test.dart';
import 'package:razcrypto_checkout/razcrypto_checkout.dart';

void main() {
  const pay = 'pay_3fK9sQ2mZt7LxR1aPq0B';
  final pk = 'pk_test_${'a' * 24}';

  test('key + payment id → embed URL on the pay host', () {
    final o = CheckoutOptions(
        key: pk, paymentId: pay, payHost: 'https://pay.example', locale: 'hi');
    expect(o.embedUrl.toString(),
        'https://pay.example/embed/$pay?key=$pk&locale=hi');
    expect(o.payOrigin, 'https://pay.example');
  });

  test('checkout_url keeps its host and token', () {
    final o =
        CheckoutOptions.fromCheckoutUrl('https://pay.example/$pay?t=ct_abc');
    expect(o.embedUrl.toString(), 'https://pay.example/embed/$pay?t=ct_abc');
    expect(
        CheckoutOptions.fromCheckoutUrl('http://10.0.2.2:3000/$pay?t=ct_1')
            .payOrigin,
        'http://10.0.2.2:3000');
  });

  test('refuses secret keys and bad input', () {
    expect(
        () => CheckoutOptions(
            key: 'sk_live_${'a' * 24}',
            paymentId: pay,
            payHost: 'https://pay.example'),
        throwsArgumentError);
    expect(
        () => CheckoutOptions(
            key: pk, paymentId: 'nope', payHost: 'https://pay.example'),
        throwsArgumentError);
    expect(
        () => CheckoutOptions(
            key: pk, paymentId: pay, payHost: 'http://evil.example'),
        throwsArgumentError);
    expect(
        () => CheckoutOptions.fromCheckoutUrl('https://pay.example/whatever'),
        throwsArgumentError);
    expect(CheckoutOptions(key: pk, paymentId: pay).payOrigin,
        'https://razcryptogateway.com'); // official host by default
  });

  test('bridge messages: only ours, success payload mapped', () {
    expect(BridgeMessage.parse('{"source":"other","type":"success"}'), isNull);
    expect(BridgeMessage.parse('not json'), isNull);
    final m = BridgeMessage.parse(
      '{"source":"razcrypto","type":"success","payload":{"payment_id":"$pay","reference_id":null,"status":"paid","signature":"ab"}}',
    )!;
    expect(m.type, 'success');
    expect(m.toSuccess(),
        const CheckoutSuccess(paymentId: pay, status: 'paid', signature: 'ab'));
  });
}
