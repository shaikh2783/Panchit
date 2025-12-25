class Address {
  final String addressId;
  final String userId;
  final String title;
  final String country;
  final String city;
  final String zipCode;
  final String phone;
  final String details;

  Address({
    required this.addressId,
    required this.userId,
    required this.title,
    required this.country,
    required this.city,
    required this.zipCode,
    required this.phone,
    required this.details,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressId: json['address_id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['address_title'] ?? '',
      country: json['address_country'] ?? '',
      city: json['address_city'] ?? '',
      zipCode: json['address_zip_code'] ?? '',
      phone: json['address_phone'] ?? '',
      details: json['address_details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'country': country,
      'city': city,
      'zip_code': zipCode,
      'phone': phone,
      'address': details,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'address_id': addressId,
      'title': title,
      'country': country,
      'city': city,
      'zip_code': zipCode,
      'phone': phone,
      'address': details,
    };
  }

  String get fullAddress {
    return '$details\n$city, $zipCode\n$country';
  }

  String get shortAddress {
    return '$city, $country';
  }

  Address copyWith({
    String? addressId,
    String? userId,
    String? title,
    String? country,
    String? city,
    String? zipCode,
    String? phone,
    String? details,
  }) {
    return Address(
      addressId: addressId ?? this.addressId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      country: country ?? this.country,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      details: details ?? this.details,
    );
  }
}
