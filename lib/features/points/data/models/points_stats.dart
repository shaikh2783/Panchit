class PointsStats {
  final double currentBalance;
  final double balanceValue;
  final double totalEarned;
  final double earnedToday;
  final int remainingToday;
  final int dailyLimit;
  final double totalWithdrawn;
  final double totalPending;
  final String currency;
  final double pointsPerCurrency;

  PointsStats({
    required this.currentBalance,
    required this.balanceValue,
    required this.totalEarned,
    required this.earnedToday,
    required this.remainingToday,
    required this.dailyLimit,
    required this.totalWithdrawn,
    required this.totalPending,
    required this.currency,
    required this.pointsPerCurrency,
  });

  factory PointsStats.fromJson(Map<String, dynamic> json) {
    return PointsStats(
      currentBalance:
          double.tryParse(json['current_balance'].toString()) ?? 0.0,
      balanceValue: double.tryParse(json['balance_value'].toString()) ?? 0.0,
      totalEarned: double.tryParse(json['total_earned'].toString()) ?? 0.0,
      earnedToday: double.tryParse(json['earned_today'].toString()) ?? 0.0,
      remainingToday: json['remaining_today'] ?? 0,
      dailyLimit: json['daily_limit'] ?? 100,
      totalWithdrawn:
          double.tryParse(json['total_withdrawn'].toString()) ?? 0.0,
      totalPending: double.tryParse(json['total_pending'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'USD',
      pointsPerCurrency:
          double.tryParse(json['points_per_currency'].toString()) ?? 1000.0,
    );
  }

  int get percentageEarnedToday {
    if (dailyLimit == 0) return 0;
    return ((earnedToday / dailyLimit) * 100).toInt().clamp(0, 100);
  }

  Map<String, dynamic> toJson() => {
    'current_balance': currentBalance,
    'balance_value': balanceValue,
    'total_earned': totalEarned,
    'earned_today': earnedToday,
    'remaining_today': remainingToday,
    'daily_limit': dailyLimit,
    'total_withdrawn': totalWithdrawn,
    'total_pending': totalPending,
    'currency': currency,
    'points_per_currency': pointsPerCurrency,
  };
}
