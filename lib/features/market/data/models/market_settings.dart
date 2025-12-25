// Market Settings Model - إدارة رصيد البائع والإعدادات

class MarketSettings {
  final double userMarketBalance;
  final bool canWithdraw;
  final bool canTransferToWallet;
  final double minWithdrawal;
  final List<String> paymentMethods;
  final String? paymentMethodCustom;
  final String currency;

  /// صلاحيات السوق (من user permissions)
  final bool marketEnabled;
  final bool marketShoppingCartEnabled;
  final bool canSellProducts;
  final bool marketMoneyWithdrawEnabled;

  MarketSettings({
    required this.userMarketBalance,
    required this.canWithdraw,
    required this.canTransferToWallet,
    required this.minWithdrawal,
    required this.paymentMethods,
    this.paymentMethodCustom,
    required this.currency,
    this.marketEnabled = true,
    this.marketShoppingCartEnabled = true,
    this.canSellProducts = true,
    this.marketMoneyWithdrawEnabled = true,
  });

  factory MarketSettings.fromJson(Map<String, dynamic> json) {
    return MarketSettings(
      userMarketBalance: _toDouble(json['user_market_balance']),
      canWithdraw: _toBool(json['can_withdraw']),
      canTransferToWallet: _toBool(json['can_transfer_to_wallet']),
      minWithdrawal: _toDouble(json['min_withdrawal'] ?? 50),
      paymentMethods: _toStringList(json['payment_methods']),
      paymentMethodCustom: json['payment_method_custom'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      marketEnabled: _toBool(json['market_enabled'], fallback: true),
      marketShoppingCartEnabled: _toBool(json['market_shopping_cart_enabled'], fallback: true),
      canSellProducts: _toBool(json['can_sell_products'], fallback: true),
      marketMoneyWithdrawEnabled: _toBool(json['market_money_withdraw_enabled'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_market_balance': userMarketBalance,
      'can_withdraw': canWithdraw,
      'can_transfer_to_wallet': canTransferToWallet,
      'min_withdrawal': minWithdrawal,
      'payment_methods': paymentMethods,
      'payment_method_custom': paymentMethodCustom,
      'currency': currency,
      'market_enabled': marketEnabled,
      'market_shopping_cart_enabled': marketShoppingCartEnabled,
      'can_sell_products': canSellProducts,
      'market_money_withdraw_enabled': marketMoneyWithdrawEnabled,
    };
  }

  bool get canWithdrawMoney =>
      canWithdraw && marketMoneyWithdrawEnabled && userMarketBalance >= minWithdrawal;

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
