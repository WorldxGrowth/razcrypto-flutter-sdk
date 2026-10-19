# razcrypto_checkout example

1. Your server creates a payment with its secret key (`POST /v1/payments`) and sends the app the
   `checkout_url` (or the payment id).
2. The app opens the checkout with `RazCryptoCheckout.open`.
3. On `CheckoutSuccess`, your server verifies the signature and waits for the `payment.paid` webhook.

Run on Android or iOS: `flutter create .` (adds platform folders), then `flutter run`.
