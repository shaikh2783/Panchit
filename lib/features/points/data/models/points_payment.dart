class PointsPayment {
  final String paymentId;
  final String userId;
  final double amount;
  final String method;
  final String methodValue;
  final String time;
  final String status;
  final String statusText;
  final String methodDisplay;

  PointsPayment({
    required this.paymentId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.methodValue,
    required this.time,
    required this.status,
    required this.statusText,
    required this.methodDisplay,
  });

  factory PointsPayment.fromJson(Map<String, dynamic> json) {
    return PointsPayment(
      paymentId: json['payment_id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      method: json['method'] ?? '',
      methodValue: json['method_value'] ?? '',
      time: json['time'] ?? '',
      status: json['status'].toString(),
      statusText: json['status_text'] ?? '',
      methodDisplay: json['method_display'] ?? '',
    );
  }

  bool get isPending => status == '0';
  bool get isPaid => status == '1';
  bool get isDeclined => status == '-1';

  Map<String, dynamic> toJson() => {
    'payment_id': paymentId,
    'user_id': userId,
    'amount': amount,
    'method': method,
    'method_value': methodValue,
    'time': time,
    'status': status,
    'status_text': statusText,
    'method_display': methodDisplay,
  };
}
