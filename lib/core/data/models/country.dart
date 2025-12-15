/// Model for country
class Country {
  final int countryId;
  final String countryName;
  final String? countryCode;
  Country({
    required this.countryId,
    required this.countryName,
    this.countryCode,
  });
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      countryId: _parseInt(json['country_id']),
      countryName: json['country_name']?.toString() ?? '',
      countryCode: json['country_code']?.toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'country_id': countryId,
      'country_name': countryName,
      if (countryCode != null) 'country_code': countryCode,
    };
  }
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  @override
  String toString() => 'Country(id: $countryId, name: $countryName, code: $countryCode)';
}
