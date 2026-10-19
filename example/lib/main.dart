import 'package:flutter/material.dart';
import 'package:razcrypto_checkout/razcrypto_checkout.dart';

void main() => runApp(const MaterialApp(home: PayScreen()));

class PayScreen extends StatefulWidget {
  const PayScreen({super.key});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  String _status = 'Not paid yet';

  /// In a real app, ask YOUR server to create the payment (secret key stays on the server)
  /// and return its `checkout_url`.
  Future<String> _createPaymentOnServer() async {
    return 'https://razcryptogateway.com/pay_XXXXXXXXXXXXXXXXXXXX?t=ct_from_your_server';
  }

  Future<void> _pay() async {
    final checkoutUrl = await _createPaymentOnServer();
    if (!mounted) return;

    final result = await RazCryptoCheckout.open(
      context,
      CheckoutOptions.fromCheckoutUrl(checkoutUrl),
      // or: CheckoutOptions(key: 'pk_live_…', paymentId: 'pay_…'),
    );

    setState(() {
      _status = switch (result) {
        // Send paymentId + signature to your server; ship after the payment.paid webhook.
        CheckoutSuccess(:final paymentId) => 'Paid: $paymentId',
        CheckoutPending(:final paymentId) => 'Confirming on-chain: $paymentId',
        CheckoutCancelled() => 'Cancelled',
        CheckoutFailed(:final message) => 'Failed: $message',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RazCrypto checkout')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status),
            const SizedBox(height: 16),
            FilledButton(onPressed: _pay, child: const Text('Pay with crypto')),
          ],
        ),
      ),
    );
  }
}
