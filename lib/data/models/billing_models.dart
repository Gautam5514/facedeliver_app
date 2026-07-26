/// A purchasable plan. `amount` is in the smallest currency unit (paise),
/// exactly as Razorpay expects it — divide by 100 only for display.
class BillingPlan {
  const BillingPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.uploadLimit,
  });

  final String id;
  final String code;
  final String name;
  final int amount;
  final String currency;
  final String billingCycle;
  final int uploadLimit;

  String get cycleLabel => switch (billingCycle) {
        'monthly' => 'per month',
        'yearly' => 'per year',
        'one_time' => 'one time',
        _ => billingCycle,
      };

  factory BillingPlan.fromJson(Map<String, dynamic> json) => BillingPlan(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        code: (json['code'] as String? ?? '').trim(),
        name: (json['name'] as String? ?? 'Plan').trim(),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        currency: (json['currency'] as String? ?? 'INR').trim(),
        billingCycle: (json['billingCycle'] as String? ?? 'monthly').trim(),
        uploadLimit: (json['uploadLimit'] as num?)?.toInt() ?? 0,
      );
}

class Subscription {
  const Subscription({
    required this.id,
    required this.status,
    required this.uploadLimit,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.planName,
    required this.planCode,
    required this.amount,
    required this.currency,
  });

  final String id;
  final String status;
  final int uploadLimit;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final String planName;
  final String planCode;
  final int amount;
  final String currency;

  bool get isActive => status == 'active';

  int? get daysRemaining {
    if (currentPeriodEnd == null) return null;
    final diff = currentPeriodEnd!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>?;
    return Subscription(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] as String? ?? 'unknown').trim(),
      uploadLimit: (json['uploadLimit'] as num?)?.toInt() ?? 0,
      currentPeriodStart:
          DateTime.tryParse(json['currentPeriodStart']?.toString() ?? ''),
      currentPeriodEnd:
          DateTime.tryParse(json['currentPeriodEnd']?.toString() ?? ''),
      planName: (plan?['name'] as String? ?? 'Plan').trim(),
      planCode: (plan?['code'] as String? ?? '').trim(),
      amount: (plan?['amount'] as num?)?.toInt() ?? 0,
      currency: (plan?['currency'] as String? ?? 'INR').trim(),
    );
  }
}

class UploadUsage {
  const UploadUsage({
    required this.usedUploads,
    required this.remainingUploads,
    required this.resetDate,
  });

  final int usedUploads;
  final int remainingUploads;
  final DateTime? resetDate;

  factory UploadUsage.fromJson(Map<String, dynamic> json) => UploadUsage(
        usedUploads: (json['usedUploads'] as num?)?.toInt() ?? 0,
        remainingUploads: (json['remainingUploads'] as num?)?.toInt() ?? 0,
        resetDate: DateTime.tryParse(json['resetDate']?.toString() ?? ''),
      );
}

/// `GET /billing/status`. Both fields are null until a plan is activated —
/// uploads are blocked in that state, so the UI must say so plainly.
class BillingStatus {
  const BillingStatus({this.subscription, this.usage});

  final Subscription? subscription;
  final UploadUsage? usage;

  static const none = BillingStatus();

  bool get hasPlan => subscription != null && usage != null;

  int get uploadLimit => subscription?.uploadLimit ?? 0;

  int get remainingUploads => usage?.remainingUploads ?? 0;

  /// 0–100, clamped. Used for the quota bar and its severity colour.
  int get usagePercent {
    if (!hasPlan) return 0;
    final limit = uploadLimit <= 0 ? 1 : uploadLimit;
    final percent = (usage!.usedUploads / limit * 100).round();
    return percent.clamp(0, 100);
  }

  factory BillingStatus.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'] as Map<String, dynamic>?;
    final usage = json['usage'] as Map<String, dynamic>?;
    return BillingStatus(
      subscription:
          subscription == null ? null : Subscription.fromJson(subscription),
      usage: usage == null ? null : UploadUsage.fromJson(usage),
    );
  }
}

/// The Razorpay order plus the key id needed to open checkout.
class CheckoutOrder {
  const CheckoutOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.razorpayKeyId,
    required this.planName,
  });

  final String orderId;
  final int amount;
  final String currency;
  final String razorpayKeyId;
  final String planName;

  factory CheckoutOrder.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>? ?? const {};
    final plan = json['plan'] as Map<String, dynamic>? ?? const {};
    return CheckoutOrder(
      orderId: (order['id'] ?? '').toString(),
      amount: (order['amount'] as num?)?.toInt() ?? 0,
      currency: (order['currency'] as String? ?? 'INR').trim(),
      razorpayKeyId: (json['razorpayKeyId'] as String? ?? '').trim(),
      planName: (plan['name'] as String? ?? 'Plan').trim(),
    );
  }
}
