import 'package:equatable/equatable.dart';

class WalletPackage extends Equatable {
  const WalletPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.currencySymbol,
    this.period,
    this.features = const {},
    this.description,
    this.color,
    this.isRecommended = false,
    this.isPopular = false,
    this.icon,
    this.permissionsGroupId,
    this.permissions,
    this.billingPlans,
    this.subscription,
  });

  final int id;
  final String name;
  final double price;
  final String currency;
  final String currencySymbol;
  final WalletPackagePeriod? period;
  final Map<String, dynamic> features;
  final String? description;
  final String? color;
  final bool isRecommended;
  final bool isPopular;
  final String? icon;
  final int? permissionsGroupId;
  final WalletPackagePermissions? permissions;
  final Map<String, dynamic>? billingPlans;
  final WalletPackageSubscription? subscription;

  factory WalletPackage.fromJson(Map<String, dynamic> json) {
    final features = _parseFeatures(json['features']);
    return WalletPackage(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      price: _toDouble(json['price']),
      currency: _toString(json['currency']),
      currencySymbol: _toString(
        json['currency_symbol'],
        fallback: _toString(json['currency']),
      ),
      period: WalletPackagePeriod.tryParse(json['period']),
      features: features,
      description: _nullableString(json['description']),
      color: _nullableString(json['color']),
      isRecommended:
          _toBool(json['is_recommended']) ||
          _toBool(json['recommended']) ||
          _toBool(json['is_featured']),
      isPopular: _toBool(json['is_popular']) || _toBool(json['popular']),
      icon: _nullableString(json['icon']),
      permissionsGroupId: _toNullableInt(json['permissions_group_id']),
      permissions: json['permissions'] is Map<String, dynamic>
          ? WalletPackagePermissions.fromJson(
              json['permissions'] as Map<String, dynamic>,
            )
          : null,
      billingPlans: json['billing_plans'] is Map<String, dynamic>
          ? Map<String, dynamic>.unmodifiable(
              json['billing_plans'] as Map<String, dynamic>,
            )
          : null,
      subscription: json['subscription'] is Map<String, dynamic>
          ? WalletPackageSubscription.fromJson(
              json['subscription'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String get formattedPrice {
    final formattedAmount = _formatAmount(price);
    final symbol = currencySymbol.isNotEmpty ? currencySymbol : currency;
    if (symbol.length == 1) {
      return '$symbol$formattedAmount';
    }
    if (symbol == currency) {
      return '$symbol $formattedAmount';
    }
    return '$symbol$formattedAmount';
  }

  bool get hasPeriod => period != null;

  bool get isCurrentPlan => subscription?.isCurrentlyActive ?? false;

  bool get wasPurchased => subscription != null;

  bool get isSubscriptionExpired => subscription?.isExpired ?? false;

  bool get canRenew => wasPurchased && !isCurrentPlan;

  String? get subscriptionStatusLabel => subscription?.statusLabel;

  String? get subscriptionSecondaryLabel => subscription?.secondaryStatusLabel;

  String? get subscriptionPurchasedLabel => subscription?.purchasedOnLabel;

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    currency,
    currencySymbol,
    period,
    features,
    description,
    color,
    isRecommended,
    isPopular,
    icon,
    permissionsGroupId,
    permissions,
    billingPlans,
    subscription,
  ];
}

class WalletPackagePermissions extends Equatable {
  const WalletPackagePermissions({
    this.groupId,
    this.groupTitle,
    this.capabilities = const {},
    this.affiliates,
    this.points,
  });

  final int? groupId;
  final String? groupTitle;
  final Map<String, bool> capabilities;
  final Map<String, dynamic>? affiliates;
  final Map<String, dynamic>? points;

  factory WalletPackagePermissions.fromJson(Map<String, dynamic> json) {
    final rawCapabilities = json['capabilities'];
    final parsedCapabilities = <String, bool>{};
    if (rawCapabilities is Map<String, dynamic>) {
      rawCapabilities.forEach((key, value) {
        parsedCapabilities[key] = _toBool(value);
      });
    }

    return WalletPackagePermissions(
      groupId: _toNullableInt(json['group_id']),
      groupTitle: _nullableString(json['group_title']),
      capabilities: Map<String, bool>.unmodifiable(parsedCapabilities),
      affiliates: json['affiliates'] is Map<String, dynamic>
          ? Map<String, dynamic>.unmodifiable(
              json['affiliates'] as Map<String, dynamic>,
            )
          : null,
      points: json['points'] is Map<String, dynamic>
          ? Map<String, dynamic>.unmodifiable(
              json['points'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  bool get hasCapabilities => capabilities.isNotEmpty;

  @override
  List<Object?> get props => [
    groupId,
    groupTitle,
    capabilities,
    affiliates,
    points,
  ];
}

class WalletPackageSubscription extends Equatable {
  const WalletPackageSubscription({
    required this.isActive,
    required this.isExpired,
    required this.isLifetime,
    this.subscribedAt,
    this.expiresAt,
    this.expiresInSeconds,
  });

  final bool isActive;
  final bool isExpired;
  final bool isLifetime;
  final DateTime? subscribedAt;
  final DateTime? expiresAt;
  final int? expiresInSeconds;

  factory WalletPackageSubscription.fromJson(Map<String, dynamic> json) {
    return WalletPackageSubscription(
      isActive: _toBool(json['is_active']),
      isExpired: _toBool(json['is_expired']),
      isLifetime: _toBool(json['is_lifetime']),
      subscribedAt: _parseDateTime(json['subscribed_at']),
      expiresAt: _parseDateTime(json['expires_at']),
      expiresInSeconds: _toNullableInt(json['expires_in_seconds']),
    );
  }

  bool get isCurrentlyActive => isActive && !isExpired;

  String? get statusLabel {
    if (isCurrentlyActive) {
      return 'Current package';
    }
    if (isExpired) {
      return 'Package expired';
    }
    if (subscribedAt != null) {
      return 'Previously activated';
    }
    return null;
  }

  String? get secondaryStatusLabel {
    if (isCurrentlyActive) {
      if (isLifetime) {
        return 'Lifetime membership active';
      }
      final expiry = expiresAt;
      if (expiry != null) {
        return 'Renews on ${_formatDate(expiry, includeTime: true)}';
      }
      return null;
    }
    if (isExpired) {
      final expiry = expiresAt;
      if (expiry != null) {
        return 'Expired on ${_formatDate(expiry, includeTime: true)}';
      }
      return 'Subscription expired';
    }
    final purchase = subscribedAt;
    if (purchase != null) {
      return 'Purchased on ${_formatDate(purchase, includeTime: true)}';
    }
    return null;
  }

  String? get purchasedOnLabel {
    if (subscribedAt == null) {
      return null;
    }
    return _formatDate(subscribedAt!, includeTime: true);
  }

  String? get expiryLabel {
    if (expiresAt == null) {
      return null;
    }
    return _formatDate(expiresAt!, includeTime: true);
  }

  @override
  List<Object?> get props => [
    isActive,
    isExpired,
    isLifetime,
    subscribedAt,
    expiresAt,
    expiresInSeconds,
  ];
}

class WalletPackagePeriod extends Equatable {
  const WalletPackagePeriod({required this.number, required this.type});

  final int number;
  final String type;

  factory WalletPackagePeriod.fromJson(Map<String, dynamic> json) {
    return WalletPackagePeriod(
      number: _toInt(json['number']),
      type: _toString(json['type']),
    );
  }

  static WalletPackagePeriod? tryParse(Object? value) {
    if (value is Map<String, dynamic>) {
      return WalletPackagePeriod.fromJson(value);
    }
    return null;
  }

  String get label {
    final normalized = type.toLowerCase();
    final plural = _pluralize(normalized, number);
    return '$number $plural';
  }

  @override
  List<Object?> get props => [number, type];
}

int _toInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

int? _toNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double _toDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _toString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final string = value.toString();
  return string.isEmpty ? null : string;
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

Map<String, dynamic> _parseFeatures(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.unmodifiable(value);
  }
  if (value is List) {
    final mapped = <String, dynamic>{};
    for (var i = 0; i < value.length; i++) {
      mapped['item_$i'] = value[i];
    }
    return Map<String, dynamic>.unmodifiable(mapped);
  }
  return const {};
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  if (value is int) {
    // Some payloads use unix timestamps in seconds.
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.toInt() * 1000,
      isUtc: true,
    );
  }
  return null;
}

String _formatDate(DateTime value, {bool includeTime = false}) {
  final local = value.toLocal();
  final date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  if (!includeTime) {
    return date;
  }
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String _formatAmount(double value) {
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String _pluralize(String word, int count) {
  if (count == 1) return word;
  switch (word) {
    case 'day':
      return 'days';
    case 'week':
      return 'weeks';
    case 'month':
      return 'months';
    case 'year':
      return 'years';
    default:
      return '${word}s';
  }
}
