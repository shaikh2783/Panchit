class Gender {
  final String id;
  final String name;
  final String order;

  Gender({
    required this.id,
    required this.name,
    required this.order,
  });

  factory Gender.fromJson(Map<String, dynamic> json) {
    return Gender(
      id: json['gender_id']?.toString() ?? '',
      name: json['gender_name']?.toString() ?? '',
      order: json['gender_order']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender_id': id,
      'gender_name': name,
      'gender_order': order,
    };
  }
}
