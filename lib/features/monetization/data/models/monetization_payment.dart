class MonetizationPayment {
  final String paymentId;
  final String userId;
  final double amount;
  final String method;
  final String methodValue;
  final String time;
  final String status;

  MonetizationPayment({
    required this.paymentId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.methodValue,
    required this.time,
    required this.status,
  });

  factory MonetizationPayment.fromJson(Map<String, dynamic> json) {
    return MonetizationPayment(
      paymentId: json['payment_id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: double.parse(json['amount']?.toString() ?? '0'),
      method: json['method'] ?? '',
      methodValue: json['method_value'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
    );
  }

  String get statusText {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'declined':
        return 'Declined';
      default:
        return status;
    }
  }

  String get methodText {
    switch (method) {
      case 'paypal':
        return 'PayPal';
      case 'bank':
        return 'Bank Transfer';
      case 'skrill':
        return 'Skrill';
      case 'moneypoolscash':
        return 'MoneyPoolsCash';
      default:
        return method;
    }
  }
}
