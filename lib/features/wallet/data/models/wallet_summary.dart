import 'package:equatable/equatable.dart';
class WalletSummary extends Equatable {
  const WalletSummary({
    required this.wallet,
    required this.balances,
    required this.points,
    required this.tips,
    required this.withdrawalSources,
    this.updatedAt,
  });
  final WalletInfo wallet;
  final WalletBalances balances;
  final WalletPoints points;
  final WalletTips tips;
  final Map<String, WalletWithdrawalSource> withdrawalSources;
  final DateTime? updatedAt;
  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      wallet: WalletInfo.fromJson(_map(json['wallet'])),
      balances: WalletBalances.fromJson(_map(json['balances'])),
      points: WalletPoints.fromJson(_map(json['points'])),
      tips: WalletTips.fromJson(_map(json['tips'])),
      withdrawalSources: _parseWithdrawalSources(json['withdrawal_sources']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }
  WalletSummary copyWith({
    WalletInfo? wallet,
    WalletBalances? balances,
    WalletPoints? points,
    WalletTips? tips,
    Map<String, WalletWithdrawalSource>? withdrawalSources,
    DateTime? updatedAt,
  }) {
    return WalletSummary(
      wallet: wallet ?? this.wallet,
      balances: balances ?? this.balances,
      points: points ?? this.points,
      tips: tips ?? this.tips,
      withdrawalSources: withdrawalSources ?? this.withdrawalSources,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  static Map<String, WalletWithdrawalSource> _parseWithdrawalSources(
    Object? value,
  ) {
    if (value is Map<String, dynamic>) {
      return value.map(
        (key, data) =>
            MapEntry(key, WalletWithdrawalSource.fromJson(_map(data))),
      );
    }
    return const {};
  }
  static Map<String, dynamic> _map(Object? source) {
    if (source is Map<String, dynamic>) {
      return source;
    }
    return const {};
  }
  static DateTime? _parseDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
  @override
  List<Object?> get props => [
    wallet,
    balances,
    points,
    tips,
    withdrawalSources,
    updatedAt,
  ];
}
class WalletInfo extends Equatable {
  const WalletInfo({
    required this.balance,
    required this.currency,
    required this.currencySymbol,
    required this.enabled,
    required this.transferEnabled,
    required this.maxTransfer,
    required this.withdrawalEnabled,
    required this.minWithdrawal,
    required this.paymentMethods,
  });
  final double balance;
  final String currency;
  final String currencySymbol;
  final bool enabled;
  final bool transferEnabled;
  final double maxTransfer;
  final bool withdrawalEnabled;
  final double minWithdrawal;
  final List<String> paymentMethods;
  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      balance: _toDouble(json['balance'], fallback: 0),
      currency: _toString(json['currency']),
      currencySymbol: _toString(json['currency_symbol'], fallback: ''),
      enabled: _toBool(json['enabled']),
      transferEnabled: _toBool(json['transfer_enabled']),
      maxTransfer: _toDouble(json['max_transfer'], fallback: 0),
      withdrawalEnabled: _toBool(json['withdrawal_enabled']),
      minWithdrawal: _toDouble(json['min_withdrawal'], fallback: 0),
      paymentMethods: _parseStringList(json['payment_methods']),
    );
  }
  WalletInfo copyWith({
    double? balance,
    String? currency,
    String? currencySymbol,
    bool? enabled,
    bool? transferEnabled,
    double? maxTransfer,
    bool? withdrawalEnabled,
    double? minWithdrawal,
    List<String>? paymentMethods,
  }) {
    return WalletInfo(
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      enabled: enabled ?? this.enabled,
      transferEnabled: transferEnabled ?? this.transferEnabled,
      maxTransfer: maxTransfer ?? this.maxTransfer,
      withdrawalEnabled: withdrawalEnabled ?? this.withdrawalEnabled,
      minWithdrawal: minWithdrawal ?? this.minWithdrawal,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
  @override
  List<Object?> get props => [
    balance,
    currency,
    currencySymbol,
    enabled,
    transferEnabled,
    maxTransfer,
    withdrawalEnabled,
    minWithdrawal,
    paymentMethods,
  ];
}
class WalletBalances extends Equatable {
  const WalletBalances({required this.entries});
  final Map<String, double> entries;
  factory WalletBalances.fromJson(Map<String, dynamic> json) {
    final mapped = <String, double>{};
    json.forEach((key, value) {
      mapped[key] = _toDouble(value, fallback: 0);
    });
    return WalletBalances(entries: mapped);
  }
  double operator [](String key) => entries[key] ?? 0;
  WalletBalances copyWith({Map<String, double>? entries}) {
    return WalletBalances(entries: entries ?? this.entries);
  }
  @override
  List<Object?> get props => [entries];
}
class WalletPoints extends Equatable {
  const WalletPoints({
    required this.enabled,
    required this.balance,
    required this.rate,
    required this.value,
    required this.canWithdraw,
  });
  final bool enabled;
  final double balance;
  final double rate;
  final double value;
  final bool canWithdraw;
  factory WalletPoints.fromJson(Map<String, dynamic> json) {
    return WalletPoints(
      enabled: _toBool(json['enabled']),
      balance: _toDouble(json['balance'], fallback: 0),
      rate: _toDouble(json['rate'], fallback: 0),
      value: _toDouble(json['value'], fallback: 0),
      canWithdraw: _toBool(json['can_withdraw']),
    );
  }
  WalletPoints copyWith({
    bool? enabled,
    double? balance,
    double? rate,
    double? value,
    bool? canWithdraw,
  }) {
    return WalletPoints(
      enabled: enabled ?? this.enabled,
      balance: balance ?? this.balance,
      rate: rate ?? this.rate,
      value: value ?? this.value,
      canWithdraw: canWithdraw ?? this.canWithdraw,
    );
  }
  @override
  List<Object?> get props => [enabled, balance, rate, value, canWithdraw];
}
class WalletTips extends Equatable {
  const WalletTips({
    required this.enabled,
    required this.minAmount,
    required this.maxAmount,
  });
  final bool enabled;
  final double minAmount;
  final double maxAmount;
  factory WalletTips.fromJson(Map<String, dynamic> json) {
    return WalletTips(
      enabled: _toBool(json['enabled']),
      minAmount: _toDouble(json['min_amount'], fallback: 0),
      maxAmount: _toDouble(json['max_amount'], fallback: 0),
    );
  }
  WalletTips copyWith({bool? enabled, double? minAmount, double? maxAmount}) {
    return WalletTips(
      enabled: enabled ?? this.enabled,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }
  @override
  List<Object?> get props => [enabled, minAmount, maxAmount];
}
class WalletWithdrawalSource extends Equatable {
  const WalletWithdrawalSource({
    required this.enabled,
    required this.balance,
    this.rate,
    this.value,
  });
  final bool enabled;
  final double balance;
  final double? rate;
  final double? value;
  factory WalletWithdrawalSource.fromJson(Map<String, dynamic> json) {
    return WalletWithdrawalSource(
      enabled: _toBool(json['enabled']),
      balance: _toDouble(json['balance'], fallback: 0),
      rate: _toNullableDouble(json['rate']),
      value: _toNullableDouble(json['value']),
    );
  }
  WalletWithdrawalSource copyWith({
    bool? enabled,
    double? balance,
    double? rate,
    double? value,
  }) {
    return WalletWithdrawalSource(
      enabled: enabled ?? this.enabled,
      balance: balance ?? this.balance,
      rate: rate ?? this.rate,
      value: value ?? this.value,
    );
  }
  @override
  List<Object?> get props => [enabled, balance, rate, value];
}
bool _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == '1' || lower == 'true' || lower == 'yes' || lower == 'on';
  }
  return false;
}
double _toDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}
double? _toNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
String _toString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}
List<String> _parseStringList(Object? value) {
  if (value is List) {
    return value.map((element) => element.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}
