// Funding Payment Model - طلبات السحب من رصيد التمويل

enum FundingPaymentStatus {
  pending('0'),
  approved('1'),
  declined('-1');

  final String value;
  const FundingPaymentStatus(this.value);

  String get statusText {
    switch (this) {
      case FundingPaymentStatus.pending:
        return 'Pending';
      case FundingPaymentStatus.approved:
        return 'Approved';
      case FundingPaymentStatus.declined:
        return 'Declined';
    }
  }

  static FundingPaymentStatus fromValue(dynamic value) {
    final strValue = value.toString();
    return FundingPaymentStatus.values.firstWhere(
      (e) => e.value == strValue,
      orElse: () => FundingPaymentStatus.pending,
    );
  }
}

class FundingPayment {
  final String paymentId;
  final double amount;
  final String method;
  final String methodValue;
  final String time;
  final FundingPaymentStatus status;
  final String? methodDisplay;

  FundingPayment({
    required this.paymentId,
    required this.amount,
    required this.method,
    required this.methodValue,
    required this.time,
    required this.status,
    this.methodDisplay,
  });

  factory FundingPayment.fromJson(Map<String, dynamic> json) {
    return FundingPayment(
      paymentId: json['payment_id']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      method: json['method']?.toString() ?? '',
      methodValue: json['method_value']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: FundingPaymentStatus.fromValue(json['status']),
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
