class MonetizationSettings {
  final bool canMonetize;
  final bool monetizationEnabled;
  final double chatPrice;
  final double callPrice;
  final double minPrice;
  final int totalPlans;
  final int subscribersCount;
  final List<MonetizationPlan> plans;
  final MonetizationSystemSettings systemSettings;

  MonetizationSettings({
    required this.canMonetize,
    required this.monetizationEnabled,
    required this.chatPrice,
    required this.callPrice,
    required this.minPrice,
    required this.totalPlans,
    required this.subscribersCount,
    required this.plans,
    required this.systemSettings,
  });

  factory MonetizationSettings.fromJson(Map<String, dynamic> json) {
    return MonetizationSettings(
      canMonetize: json['can_monetize'] ?? false,
      monetizationEnabled: json['monetization_enabled'] ?? false,
      chatPrice: double.parse(json['chat_price']?.toString() ?? '0'),
      callPrice: double.parse(json['call_price']?.toString() ?? '0'),
      minPrice: double.parse(json['min_price']?.toString() ?? '0'),
      totalPlans: int.parse(json['total_plans']?.toString() ?? '0'),
      subscribersCount: int.parse(json['subscribers_count']?.toString() ?? '0'),
      plans: json['monetization_plans'] != null
          ? (json['monetization_plans'] as List)
              .map((p) => MonetizationPlan.fromJson(p))
              .toList()
          : [],
      systemSettings: MonetizationSystemSettings.fromJson(
          json['system_settings'] ?? {}),
    );
  }
}

class MonetizationSystemSettings {
  final bool monetizationEnabled;
  final bool verificationRequired;
  final bool moneyWithdrawEnabled;
  final String currency;

  MonetizationSystemSettings({
    required this.monetizationEnabled,
    required this.verificationRequired,
    required this.moneyWithdrawEnabled,
    required this.currency,
  });

  factory MonetizationSystemSettings.fromJson(Map<String, dynamic> json) {
    return MonetizationSystemSettings(
      monetizationEnabled: json['monetization_enabled'] ?? false,
      verificationRequired: json['verification_required'] ?? false,
      moneyWithdrawEnabled: json['money_withdraw_enabled'] ?? false,
      currency: json['currency'] ?? 'USD',
    );
  }
}

class MonetizationPlan {
  final String planId;
  final String nodeId;
  final String nodeType;
  final String title;
  final double price;
  final String periodNum;
  final String period;
  final String? customDescription;
  final String planOrder;

  MonetizationPlan({
    required this.planId,
    required this.nodeId,
    required this.nodeType,
    required this.title,
    required this.price,
    required this.periodNum,
    required this.period,
    this.customDescription,
    required this.planOrder,
  });

  factory MonetizationPlan.fromJson(Map<String, dynamic> json) {
    return MonetizationPlan(
      planId: json['plan_id'] ?? '',
      nodeId: json['node_id'] ?? '',
      nodeType: json['node_type'] ?? '',
      title: json['title'] ?? '',
      price: double.parse(json['price']?.toString() ?? '0'),
      periodNum: json['period_num'] ?? '1',
      period: json['period'] ?? 'month',
      customDescription: json['custom_description'],
      planOrder: json['plan_order'] ?? '1',
    );
  }

  String get periodText {
    String periodName = period;
    if (periodNum != '1') {
      return '$periodNum ${periodName}s';
    }
    return periodName;
  }
}
