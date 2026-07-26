import '../../core/network/api_client.dart';
import '../models/billing_models.dart';

class BillingRepository {
  BillingRepository(this._api);

  final ApiClient _api;

  Future<List<BillingPlan>> plans() async {
    final json = await _api.get('/billing/plans');
    return ((json['plans'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BillingPlan.fromJson)
        .toList(growable: false);
  }

  Future<BillingStatus> status() async {
    final json = await _api.get('/billing/status');
    return BillingStatus.fromJson(json);
  }

  Future<CheckoutOrder> createOrder(String planCode) async {
    final json = await _api.post(
      '/billing/create-order',
      body: {'planCode': planCode},
    );
    return CheckoutOrder.fromJson(json);
  }

  /// Signature verification is what actually activates the subscription and
  /// resets the upload quota — checkout success alone is not enough.
  Future<Subscription> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final json = await _api.post('/billing/verify-payment', body: {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    });
    return Subscription.fromJson(
      (json['subscription'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
