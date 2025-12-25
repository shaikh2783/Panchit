class AffiliatePayment {
  final String paymentId;
  final String userId;
  final double amount;
  final String method;
  final String methodValue;
  final String status;
  final String time;
  final String? processedTime;

  AffiliatePayment({
    required this.paymentId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.methodValue,
    required this.status,
    required this.time,
    this.processedTime,
  });

  factory AffiliatePayment.fromJson(Map<String, dynamic> json) {
    return AffiliatePayment(
      paymentId: json['payment_id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: double.parse(json['amount'].toString()),
      method: json['method'] ?? '',
      methodValue: json['method_value'] ?? '',
      status: json['status'] ?? 'pending',
      time: json['time'] ?? '',
      processedTime: json['processed_time'],
    );
  }

  bool get isPending => status == 'pending';

  bool get isPaid => status == 'paid';

  bool get isDeclined => status == 'declined';

  String get statusText {
    switch (status) {
      case 'paid':
        return 'مدفوع';
      case 'pending':
        return 'قيد الانتظار';
      case 'declined':
        return 'مرفوض';
      default:
        return status;
    }
  }

  String get methodText {
    switch (method.toLowerCase()) {
      case 'paypal':
        return 'PayPal';
      case 'bank':
        return 'تحويل بنكي';
      case 'stripe':
        return 'Stripe';
      case 'wallet':
        return 'المحفظة';
      default:
        return method;
    }
  }
}
