class PointsSettings {
  final double userPoints;
  final double moneyBalance;
  final int remainingPointsToday;
  final int dailyLimit;
  final double pointsPerCurrency;
  final bool canWithdraw;
  final bool canTransferToWallet;
  final double minWithdrawal;
  final PointsSystemSettings systemSettings;

  PointsSettings({
    required this.userPoints,
    required this.moneyBalance,
    required this.remainingPointsToday,
    required this.dailyLimit,
    required this.pointsPerCurrency,
    required this.canWithdraw,
    required this.canTransferToWallet,
    required this.minWithdrawal,
    required this.systemSettings,
  });

  factory PointsSettings.fromJson(Map<String, dynamic> json) {
    return PointsSettings(
      userPoints: double.tryParse(json['user_points'].toString()) ?? 0.0,
      moneyBalance: double.tryParse(json['money_balance'].toString()) ?? 0.0,
      remainingPointsToday: json['remaining_points_today'] ?? 0,
      dailyLimit: json['daily_limit'] ?? 100,
      pointsPerCurrency:
          double.tryParse(json['points_per_currency'].toString()) ?? 1000.0,
      canWithdraw: json['can_withdraw'] ?? false,
      canTransferToWallet: json['can_transfer_to_wallet'] ?? false,
      minWithdrawal: double.tryParse(json['min_withdrawal'].toString()) ?? 50.0,
      systemSettings: PointsSystemSettings.fromJson(
        json['system_settings'] is Map ? json['system_settings'] : {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_points': userPoints,
    'money_balance': moneyBalance,
    'remaining_points_today': remainingPointsToday,
    'daily_limit': dailyLimit,
    'points_per_currency': pointsPerCurrency,
    'can_withdraw': canWithdraw,
    'can_transfer_to_wallet': canTransferToWallet,
    'min_withdrawal': minWithdrawal,
    'system_settings': systemSettings.toJson(),
  };
}

class PointsSystemSettings {
  final bool pointsEnabled;
  final double pointsPerPost;
  final double pointsPerPostView;
  final double pointsPerPostComment;
  final double pointsPerPostReaction;
  final double pointsPerComment;
  final double pointsPerReaction;
  final double pointsPerFollow;
  final double pointsPerReferred;
  final bool pointsMoneyWithdrawEnabled;
  final bool pointsMoneyTransferEnabled;
  final List<String> paymentMethodArray;
  final String paymentMethodCustom;
  final String currency;

  PointsSystemSettings({
    required this.pointsEnabled,
    required this.pointsPerPost,
    required this.pointsPerPostView,
    required this.pointsPerPostComment,
    required this.pointsPerPostReaction,
    required this.pointsPerComment,
    required this.pointsPerReaction,
    required this.pointsPerFollow,
    required this.pointsPerReferred,
    required this.pointsMoneyWithdrawEnabled,
    required this.pointsMoneyTransferEnabled,
    required this.paymentMethodArray,
    required this.paymentMethodCustom,
    required this.currency,
  });

  factory PointsSystemSettings.fromJson(Map<String, dynamic> json) {
    return PointsSystemSettings(
      pointsEnabled: json['points_enabled'] ?? false,
      pointsPerPost: double.tryParse(json['points_per_post'].toString()) ?? 5.0,
      pointsPerPostView:
          double.tryParse(json['points_per_post_view'].toString()) ?? 0.5,
      pointsPerPostComment:
          double.tryParse(json['points_per_post_comment'].toString()) ?? 1.0,
      pointsPerPostReaction:
          double.tryParse(json['points_per_post_reaction'].toString()) ?? 1.0,
      pointsPerComment:
          double.tryParse(json['points_per_comment'].toString()) ?? 2.0,
      pointsPerReaction:
          double.tryParse(json['points_per_reaction'].toString()) ?? 1.0,
      pointsPerFollow:
          double.tryParse(json['points_per_follow'].toString()) ?? 3.0,
      pointsPerReferred:
          double.tryParse(json['points_per_referred'].toString()) ?? 10.0,
      pointsMoneyWithdrawEnabled:
          json['points_money_withdraw_enabled'] ?? false,
      pointsMoneyTransferEnabled:
          json['points_money_transfer_enabled'] ?? false,
      paymentMethodArray: List<String>.from(
        json['points_payment_method_array'] ?? [],
      ),
      paymentMethodCustom: json['points_payment_method_custom'] ?? '',
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() => {
    'points_enabled': pointsEnabled,
    'points_per_post': pointsPerPost,
    'points_per_post_view': pointsPerPostView,
    'points_per_post_comment': pointsPerPostComment,
    'points_per_post_reaction': pointsPerPostReaction,
    'points_per_comment': pointsPerComment,
    'points_per_reaction': pointsPerReaction,
    'points_per_follow': pointsPerFollow,
    'points_per_referred': pointsPerReferred,
    'points_money_withdraw_enabled': pointsMoneyWithdrawEnabled,
    'points_money_transfer_enabled': pointsMoneyTransferEnabled,
    'points_payment_method_array': paymentMethodArray,
    'points_payment_method_custom': paymentMethodCustom,
    'currency': currency,
  };
}
