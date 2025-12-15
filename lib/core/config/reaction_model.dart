/// نموذج البيانات للتفاعلات
class Reaction {
  final String name;
  final String displayName;
  final bool enabled;
  final String? icon;
  const Reaction({
    required this.name,
    required this.displayName,
    required this.enabled,
    this.icon,
  });
  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      enabled: json['enabled'] == true || json['enabled']?.toString() == '1',
      icon: json['icon']?.toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
      'enabled': enabled,
      if (icon != null) 'icon': icon,
    };
  }
}