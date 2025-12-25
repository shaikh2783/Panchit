// Funding Stats Model - إحصاءات رصيد التمويل

class FundingStats {
  final double currentBalance;
  final double totalPaid;
  final double totalPending;
  final double totalEarned;
  final String currency;

  FundingStats({
    required this.currentBalance,
    required this.totalPaid,
    required this.totalPending,
    required this.totalEarned,
    required this.currency,
  });

  factory FundingStats.fromJson(Map<String, dynamic> json) {
    return FundingStats(
      currentBalance: _toDouble(json['current_balance']),
      totalPaid: _toDouble(json['total_paid']),
      totalPending: _toDouble(json['total_pending']),
      totalEarned: _toDouble(json['total_earned']),
      currency: json['currency']?.toString() ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_balance': currentBalance,
      'total_paid': totalPaid,
      'total_pending': totalPending,
      'total_earned': totalEarned,
      'currency': currency,
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
