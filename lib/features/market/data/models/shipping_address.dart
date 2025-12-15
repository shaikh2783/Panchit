import 'package:equatable/equatable.dart';
/// Shipping Address Model - عنوان الشحن
class ShippingAddress extends Equatable {
  final String name;
  final String phone;
  final String location;
  final String? address;
  final String? city;
  final String? zip;
  final String? country;
  const ShippingAddress({
    required this.name,
    required this.phone,
    required this.location,
    this.address,
    this.city,
    this.zip,
    this.country,
  });
  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      zip: json['zip']?.toString(),
      country: json['country']?.toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'location': location,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (zip != null) 'zip': zip,
      if (country != null) 'country': country,
    };
  }
  ShippingAddress copyWith({
    String? name,
    String? phone,
    String? location,
    String? address,
    String? city,
    String? zip,
    String? country,
  }) {
    return ShippingAddress(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      zip: zip ?? this.zip,
      country: country ?? this.country,
    );
  }
  @override
  List<Object?> get props => [name, phone, location, address, city, zip, country];
}
