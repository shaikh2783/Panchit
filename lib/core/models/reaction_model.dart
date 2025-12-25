import 'package:flutter/material.dart' show Color;
import 'package:snginepro/core/config/app_config.dart';

class ReactionModel {
  final String reactionId;
  final String reaction;
  final String title;
  final String color;
  final String image;
  final int order;
  final bool enabled;

  ReactionModel({
    required this.reactionId,
    required this.reaction,
    required this.title,
    required this.color,
    required this.image,
    required this.order,
    required this.enabled,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      reactionId: json['reaction_id']?.toString() ?? '',
      reaction: json['reaction']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      color: json['color']?.toString() ?? '#1e8bd2',
      image: json['image']?.toString() ?? '',
      order: int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      enabled: json['enabled'] == true || 
               json['enabled'] == 1 ||
               json['enabled']?.toString() == '1' ||
               json['enabled']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reaction_id': reactionId,
      'reaction': reaction,
      'title': title,
      'color': color,
      'image': image,
      'order': order,
      'enabled': enabled,
    };
  }

  ReactionModel copyWith({
    String? reactionId,
    String? reaction,
    String? title,
    String? color,
    String? image,
    int? order,
    bool? enabled,
  }) {
    return ReactionModel(
      reactionId: reactionId ?? this.reactionId,
      reaction: reaction ?? this.reaction,
      title: title ?? this.title,
      color: color ?? this.color,
      image: image ?? this.image,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
    );
  }

  /// الحصول على رابط الصورة الكامل
  String get imageUrl {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }
    String baseUrl = '${appConfig.baseUrl}/content/uploads/';
    return baseUrl + image;
  }

  /// تحويل اللون من HEX إلى Flutter Color
  Color get colorValue {
    try {
      final hexColor = color.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return const Color(0xFF1e8bd2); // لون افتراضي (أزرق)
    }
  }
}
