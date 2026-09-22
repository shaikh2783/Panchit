class RazorpayOrderResponse {
  const RazorpayOrderResponse({
    required this.keyId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.name,
    required this.description,
  });

  final String keyId;
  final String orderId;
  final int amount; // in smallest unit (paise for INR)
  final String currency;
  final String name;
  final String description;

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponse(
      keyId: json['keyId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
