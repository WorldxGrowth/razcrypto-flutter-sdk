# RazCrypto Gateway — Flutter checkout SDK

Open RazCrypto crypto checkout from your Flutter app. The customer sees the same window as on the web:
1. pick a network, then a coin
2. scan the QR, or tap "Open in MetaMask / Trust"
3. on success the screen turns green

Your app gets the result back.

- **pub.dev (after release):** `razcrypto_checkout`
- **Platforms:** Android and iOS (`webview_flutter`)
- **Keys:** client-side only, publishable key (`pk_…`). Your server creates the payment with its secret key.
- **License:** MIT

```yaml
dependencies:
  razcrypto_checkout: ^1.0.0
```

## Usage

```dart
import 'package:razcrypto_checkout/razcrypto_checkout.dart';

final result = await RazCryptoCheckout.open(
  context,
  CheckoutOptions(key: 'pk_live_…', paymentId: paymentIdFromYourServer, payHost: 'https://pay.example.com'),
  // or: CheckoutOptions.fromCheckoutUrl(checkoutUrlFromYourServer)
);

switch (result) {
  case CheckoutSuccess(:final paymentId, :final signature):
    await api.verify(paymentId, signature); // your server: verifyCheckoutSignature, then wait for payment.paid
  case CheckoutPending(:final paymentId):
    showPending(paymentId);                  // seen on-chain, confirming
  case CheckoutCancelled():
    break;
  case CheckoutFailed(:final message):
    showError(message);
}
```

## What happens
- **Bridge:** the checkout page talks to the app only through the `RazCryptoNative` JavaScript channel. Messages are accepted only while the WebView shows the pay origin.
- **Wallet links:** links to MetaMask, Trust and other wallets (and every other site) open outside the app.
- **Back button:** asks "leave this payment?". This is the same dialog as on the web, and the payment stays open.
- **After a success:**
  - The window closes by itself after the green animation.
  - `CheckoutSuccess.signature` = HMAC-SHA256(webhook secret, `payment_id|reference_id|status`). Verify it on your server.
  - Ship only after the `payment.paid` webhook.

**Android:** the merchant app in this repository (`App/app`) uses this SDK for "Customer pays on this phone". That flow was tested on an emulator: pay → success → result returned.

## Tests

```bash
flutter test
```
