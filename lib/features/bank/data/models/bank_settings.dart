// Bank Settings Model - إعدادات الحساب البنكي

class BankSettings {
  final bool enabled;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String routing;
  final String country;
  final String note;
  final String currency;

  BankSettings({
    required this.enabled,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.routing,
    required this.country,
    required this.note,
    required this.currency,
  });

  factory BankSettings.fromJson(Map<String, dynamic> json) {
    return BankSettings(
      enabled: json['enabled'] == true,
      bankName: json['bank_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      routing: json['routing']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'routing': routing,
      'country': country,
      'note': note,
      'currency': currency,
    };
  }
}
