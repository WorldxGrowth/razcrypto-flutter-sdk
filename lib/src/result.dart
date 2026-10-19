import 'dart:convert';

/// Outcome of a checkout. Always confirm on your server (webhook `payment.paid`) before shipping.
sealed class CheckoutResult {
  const CheckoutResult();
}

/// Paid. `signature` = hex HMAC-SHA256(webhook signing secret, "payment_id|reference_id|status"); verify it on
/// your server with a server SDK (`verifyCheckoutSignature`).
final class CheckoutSuccess extends CheckoutResult {
  const CheckoutSuccess(
      {required this.paymentId,
      this.referenceId,
      this.status = 'paid',
      this.signature});
  final String paymentId;
  final String? referenceId;
  final String status;
  final String? signature;

  @override
  bool operator ==(Object other) =>
      other is CheckoutSuccess &&
      other.paymentId == paymentId &&
      other.referenceId == referenceId &&
      other.status == status &&
      other.signature == signature;
  @override
  int get hashCode => Object.hash(paymentId, referenceId, status, signature);
}

/// Transfer seen on-chain, waiting for confirmations; your server gets `payment.paid` later.
final class CheckoutPending extends CheckoutResult {
  const CheckoutPending(this.paymentId);
  final String paymentId;
}

/// The customer closed checkout without paying.
final class CheckoutCancelled extends CheckoutResult {
  const CheckoutCancelled();
}

/// The page could not load.
final class CheckoutFailed extends CheckoutResult {
  const CheckoutFailed(this.code, this.message);
  final String code;
  final String message;
}

/// A message from the checkout page (`{source:"razcrypto", type, payload}`), or null when it is not ours.
class BridgeMessage {
  const BridgeMessage(this.type, this.payload);
  final String type;
  final Map<String, dynamic> payload;

  static BridgeMessage? parse(String raw) {
    try {
      final o = jsonDecode(raw);
      if (o is! Map<String, dynamic> ||
          o['source'] != 'razcrypto' ||
          o['type'] is! String) {
        return null;
      }
      final p = o['payload'];
      return BridgeMessage(
          o['type'] as String, p is Map<String, dynamic> ? p : const {});
    } on FormatException {
      return null;
    }
  }

  String? _s(String k) {
    final v = payload[k];
    return v is String && v.isNotEmpty ? v : null;
  }

  CheckoutSuccess toSuccess() => CheckoutSuccess(
      paymentId: _s('payment_id') ?? '',
      referenceId: _s('reference_id'),
      status: _s('status') ?? 'paid',
      signature: _s('signature'));
}
