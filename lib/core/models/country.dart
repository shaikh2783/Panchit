import 'package:equatable/equatable.dart';

/// نموذج الدولة
class Country extends Equatable {
  final String countryId;
  final String countryName;
  final String countryCode;

  const Country({
    required this.countryId,
    required this.countryName,
    required this.countryCode,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      countryId: json['country_id']?.toString() ?? '',
      countryName: json['country_name']?.toString() ?? '',
      countryCode: json['country_code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country_id': countryId,
      'country_name': countryName,
      'country_code': countryCode,
    };
  }

  @override
  List<Object?> get props => [countryId, countryName, countryCode];
}
