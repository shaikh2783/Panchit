// Market Payment Model - طلب السحب والدفع

enum PaymentStatus {
  pending('0'),
  approved('1'),
  declined('-1');

  final String value;
  const PaymentStatus(this.value);

  String get statusText {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.approved:
        return 'Approved';
      case PaymentStatus.declined:
        return 'Declined';
    }
  }

  static PaymentStatus fromValue(dynamic value) {
    final strValue = value.toString();
    return PaymentStatus.values.firstWhere(
      (e) => e.value == strValue,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class MarketPayment {
  final String paymentId;
  final double amount;
  final String method;
  final String methodValue;
  final String time;
  final PaymentStatus status;
  final String? methodDisplay;

  MarketPayment({
    required this.paymentId,
    required this.amount,
    required this.method,
    required this.methodValue,
    required this.time,
    required this.status,
    this.methodDisplay,
  });

  factory MarketPayment.fromJson(Map<String, dynamic> json) {
    return MarketPayment(
      paymentId: json['payment_id']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      method: json['method']?.toString() ?? '',
      methodValue: json['method_value']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: PaymentStatus.fromValue(json['status']),
      methodDisplay: json['method_display']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'amount': amount,
      'method': method,
      'method_value': methodValue,
      'time': time,
      'status': status.value,
      'method_display': methodDisplay,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
