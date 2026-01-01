import 'package:equatable/equatable.dart';

/// Shipping Address Model - عنوان الشحن
/// 
/// حسب API الجديد، الحقول المطلوبة:
/// - name (اسم المستقبل)
/// - phone (رقم الهاتف)
/// - location (العنوان الكامل)
/// 
/// الحقول الاختيارية:
/// - country (الدولة)
/// - city (المدينة)
/// - zip_code (الرمز البريدي)
class ShippingAddress extends Equatable {
  final String name;
  final String phone;
  final String address; // location في API
  final String? city;
  final String? zipCode; // zip_code في API
  final String? country;

  const ShippingAddress({
    required this.name,
    required this.phone,
    required this.address,
    this.city,
    this.zipCode,
    this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      name: json['address_title']?.toString() ?? 
           json['name']?.toString() ?? '',
      phone: json['address_phone']?.toString() ?? 
            json['phone']?.toString() ?? '',
      address: json['address_details']?.toString() ?? 
              json['location']?.toString() ?? 
              json['address']?.toString() ?? '',
      city: json['address_city']?.toString() ?? 
           json['city']?.toString(),
      zipCode: json['address_zip_code']?.toString() ?? 
              json['zip_code']?.toString() ?? 
              json['zip']?.toString(),
      country: json['address_country']?.toString() ?? 
              json['country']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'location': address, // API يتوقع location
      if (city != null) 'city': city,
      if (zipCode != null) 'zip_code': zipCode, // API يتوقع zip_code
      if (country != null) 'country': country,
    };
  }

  ShippingAddress copyWith({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? zipCode,
    String? country,
  }) {
    return ShippingAddress(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
    );
  }

  @override
  List<Object?> get props => [name, phone, address, city, zipCode, country];
}
