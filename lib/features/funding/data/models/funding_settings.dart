// Funding Settings Model - إعدادات رصيد التمويل والسحب

class FundingSettings {
  final double userFundingBalance;
  final bool canWithdraw;
  final bool canTransferToWallet;
  final double minWithdrawal;
  final List<String> paymentMethods;
  final String? paymentMethodCustom;
  final String currency;

  // صلاحيات/تفعيل من النظام
  final bool fundingMoneyWithdrawEnabled;
  final bool fundingMoneyTransferEnabled;
  final bool canRaiseFunding;

  FundingSettings({
    required this.userFundingBalance,
    required this.canWithdraw,
    required this.canTransferToWallet,
    required this.minWithdrawal,
    required this.paymentMethods,
    this.paymentMethodCustom,
    required this.currency,
    this.fundingMoneyWithdrawEnabled = true,
    this.fundingMoneyTransferEnabled = true,
    this.canRaiseFunding = true,
  });

  factory FundingSettings.fromJson(Map<String, dynamic> json) {
    return FundingSettings(
      userFundingBalance: _toDouble(json['user_funding_balance']),
      canWithdraw: _toBool(json['can_withdraw']),
      canTransferToWallet: _toBool(json['can_transfer_to_wallet']),
      minWithdrawal: _toDouble(json['min_withdrawal'] ?? 0),
      paymentMethods: _toStringList(json['payment_methods']),
      paymentMethodCustom: json['payment_method_custom'] as String?,
      currency: json['currency']?.toString() ?? 'USD',
      fundingMoneyWithdrawEnabled: _toBool(json['funding_money_withdraw_enabled'], fallback: true),
      fundingMoneyTransferEnabled: _toBool(json['funding_money_transfer_enabled'], fallback: true),
      canRaiseFunding: _toBool(json['can_raise_funding'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_funding_balance': userFundingBalance,
      'can_withdraw': canWithdraw,
      'can_transfer_to_wallet': canTransferToWallet,
      'min_withdrawal': minWithdrawal,
      'payment_methods': paymentMethods,
      'payment_method_custom': paymentMethodCustom,
      'currency': currency,
      'funding_money_withdraw_enabled': fundingMoneyWithdrawEnabled,
      'funding_money_transfer_enabled': fundingMoneyTransferEnabled,
      'can_raise_funding': canRaiseFunding,
    };
  }

  bool get canWithdrawMoney =>
      canWithdraw && fundingMoneyWithdrawEnabled && userFundingBalance >= minWithdrawal;

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == '1' || lower == 'true' || lower == 'yes';
    }
    return fallback;
  }
}
