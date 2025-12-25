class AffiliatesSettings {
  final double userAffiliateBalance;
  final String userName;
  final String referralUrl;
  final int affiliatesCount;
  final List<AffiliatedUserSetting> affiliates;
  final AffiliatesSystemSettings systemSettings;
  final String currency;

  AffiliatesSettings({
    required this.userAffiliateBalance,
    required this.userName,
    required this.referralUrl,
    required this.affiliatesCount,
    required this.affiliates,
    required this.systemSettings,
    required this.currency,
  });

  factory AffiliatesSettings.fromJson(Map<String, dynamic> json) {
    return AffiliatesSettings(
      userAffiliateBalance: double.parse(json['user_affiliate_balance'].toString()),
      userName: json['user_name'] ?? '',
      referralUrl: json['referral_url'] ?? '',
      affiliatesCount: json['affiliates_count'] ?? 0,
      affiliates: (json['affiliates'] as List?)
              ?.map((e) => AffiliatedUserSetting.fromJson(e))
              .toList() ??
          [],
      systemSettings: AffiliatesSystemSettings.fromJson(json['system_settings'] ?? {}),
      currency: json['currency'] ?? 'USD',
    );
  }
}

class AffiliatedUserSetting {
  final String userId;
  final String userName;
  final String userFirstname;
  final String userLastname;
  final String userPicture;
  final String connectionDate;
  final bool isActive;

  AffiliatedUserSetting({
    required this.userId,
    required this.userName,
    required this.userFirstname,
    required this.userLastname,
    required this.userPicture,
    required this.connectionDate,
    required this.isActive,
  });

  factory AffiliatedUserSetting.fromJson(Map<String, dynamic> json) {
    return AffiliatedUserSetting(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userFirstname: json['user_firstname'] ?? '',
      userLastname: json['user_lastname'] ?? '',
      userPicture: json['user_picture'] ?? '',
      connectionDate: json['connection_date'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  String get fullName => '$userFirstname $userLastname'.trim();
}

class AffiliatesSystemSettings {
  final String affiliatesPerUser;
  final String affiliatesPercentage;
  final String affiliateType;
  final String affiliatePaymentType;
  final String affiliatesLevels;
  final bool affiliatesMoneyWithdrawEnabled;
  final String? affiliatesPerUser2;
  final String? affiliatesPercentage2;
  final String? affiliatesPerUser3;
  final String? affiliatesPercentage3;
  final String? affiliatesPerUser4;
  final String? affiliatesPercentage4;
  final String? affiliatesPerUser5;
  final String? affiliatesPercentage5;

  AffiliatesSystemSettings({
    required this.affiliatesPerUser,
    required this.affiliatesPercentage,
    required this.affiliateType,
    required this.affiliatePaymentType,
    required this.affiliatesLevels,
    required this.affiliatesMoneyWithdrawEnabled,
    this.affiliatesPerUser2,
    this.affiliatesPercentage2,
    this.affiliatesPerUser3,
    this.affiliatesPercentage3,
    this.affiliatesPerUser4,
    this.affiliatesPercentage4,
    this.affiliatesPerUser5,
    this.affiliatesPercentage5,
  });

  factory AffiliatesSystemSettings.fromJson(Map<String, dynamic> json) {
    return AffiliatesSystemSettings(
      affiliatesPerUser: json['affiliates_per_user'] ?? '0',
      affiliatesPercentage: json['affiliates_percentage'] ?? '0',
      affiliateType: json['affiliate_type'] ?? 'registration',
      affiliatePaymentType: json['affiliate_payment_type'] ?? 'fixed',
      affiliatesLevels: json['affiliates_levels'] ?? '1',
      affiliatesMoneyWithdrawEnabled: json['affiliates_money_withdraw_enabled'] ?? false,
      affiliatesPerUser2: json['affiliates_per_user_2'],
      affiliatesPercentage2: json['affiliates_percentage_2'],
      affiliatesPerUser3: json['affiliates_per_user_3'],
      affiliatesPercentage3: json['affiliates_percentage_3'],
      affiliatesPerUser4: json['affiliates_per_user_4'],
      affiliatesPercentage4: json['affiliates_percentage_4'],
      affiliatesPerUser5: json['affiliates_per_user_5'],
      affiliatesPercentage5: json['affiliates_percentage_5'],
    );
  }

  int get numberOfLevels => int.parse(affiliatesLevels);

  bool get isFixedPayment => affiliatePaymentType == 'fixed';

  bool get isPercentagePayment => affiliatePaymentType == 'percentage';

  bool get isRegistrationType => affiliateType == 'registration';

  bool get isPackagesType => affiliateType == 'packages';

  String get earningsDescription {
    if (isRegistrationType && isFixedPayment) {
      return 'ستحصل على $affiliatesPerUser عن كل مستخدم جديد يسجل عبر رابطك';
    } else if (isPackagesType && isPercentagePayment) {
      return 'ستحصل على $affiliatesPercentage% من قيمة أي باقة يشتريها المستخدمون المحالون';
    } else if (isRegistrationType && isPercentagePayment) {
      return 'ستحصل على $affiliatesPercentage% عن كل مستخدم جديد يسجل عبر رابطك';
    }
    return 'ستحصل على مكافأة عن كل مستخدم يسجل عبر رابطك';
  }
}

class AffiliatesStats {
  final int totalAffiliates;
  final double currentBalance;
  final double totalPaid;
  final double totalPending;
  final double totalEarned;
  final String currency;

  AffiliatesStats({
    required this.totalAffiliates,
    required this.currentBalance,
    required this.totalPaid,
    required this.totalPending,
    required this.totalEarned,
    required this.currency,
  });

  factory AffiliatesStats.fromJson(Map<String, dynamic> json) {
    return AffiliatesStats(
      totalAffiliates: json['total_affiliates'] ?? 0,
      currentBalance: double.parse(json['current_balance'].toString()),
      totalPaid: double.parse(json['total_paid'].toString()),
      totalPending: double.parse(json['total_pending'].toString()),
      totalEarned: double.parse(json['total_earned'].toString()),
      currency: json['currency'] ?? 'USD',
    );
  }
}
