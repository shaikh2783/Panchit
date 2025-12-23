import 'dart:convert';

/// Background image information
class BackgroundImage {
  final String relative;
  final String full;

  const BackgroundImage({
    required this.relative,
    required this.full,
  });

  factory BackgroundImage.fromJson(Map<String, dynamic> json) {
    return BackgroundImage(
      relative: json['relative']?.toString() ?? '',
      full: json['full']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relative': relative,
      'full': full,
    };
  }

  @override
  String toString() => 'BackgroundImage(relative: $relative, full: $full)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackgroundImage && 
           other.relative == relative && 
           other.full == full;
  }

  @override
  int get hashCode => relative.hashCode ^ full.hashCode;
}

/// Background colors for gradients
class BackgroundColors {
  final String primary;
  final String? secondary;

  const BackgroundColors({
    required this.primary,
    this.secondary,
  });

  factory BackgroundColors.fromJson(Map<String, dynamic> json) {
    return BackgroundColors(
      primary: json['primary']?.toString() ?? '',
      secondary: json['secondary']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      if (secondary != null) 'secondary': secondary,
    };
  }

  @override
  String toString() => 'BackgroundColors(primary: $primary, secondary: $secondary)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackgroundColors && 
           other.primary == primary && 
           other.secondary == secondary;
  }

  @override
  int get hashCode => primary.hashCode ^ secondary.hashCode;
}

class PostColoredPattern {
  final String patternId;
  final String type; // 'image' or 'color'
  final BackgroundImage? backgroundImage;
  final BackgroundColors? backgroundColors;
  final String? textColor;

  const PostColoredPattern({
    required this.patternId,
    required this.type,
    this.backgroundImage,
    this.backgroundColors,
    this.textColor,
  });

  factory PostColoredPattern.fromJson(Map<String, dynamic> json) {
    // معالجة background_image - قد يكون object أو string
    BackgroundImage? backgroundImage;
    if (json['background_image'] != null) {
      final bgImage = json['background_image'];
      if (bgImage is Map<String, dynamic>) {
        // البنية الجديدة: {relative: "", full: ""}
        backgroundImage = BackgroundImage.fromJson(bgImage);
      } else if (bgImage is String && bgImage.isNotEmpty) {
        // البنية القديمة: string URL
        backgroundImage = BackgroundImage(
          relative: bgImage,
          full: bgImage.startsWith('http') 
              ? bgImage 
              : 'https://sngine.fluttercrafters.com/content/uploads/$bgImage',
        );
      }
    }
    
    // معالجة background_colors - قد يكون object أو قيم منفصلة
    BackgroundColors? backgroundColors;
    if (json['background_colors'] != null) {
      backgroundColors = BackgroundColors.fromJson(json['background_colors']);
    } else if (json['background_color_1'] != null) {
      // البنية القديمة: background_color_1, background_color_2
      backgroundColors = BackgroundColors(
        primary: json['background_color_1']?.toString() ?? '#6C5CE7',
        secondary: json['background_color_2']?.toString(),
      );
    }

    return PostColoredPattern(
      patternId: json['id']?.toString() ?? json['pattern_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'color',
      backgroundImage: backgroundImage,
      backgroundColors: backgroundColors,
      textColor: json['text_color']?.toString(),
    );
  }

  /// Safe factory method that handles different input types
  static PostColoredPattern? maybeFromJson(dynamic json) {
    if (json == null) return null;

    try {
      if (json is Map<String, dynamic>) {
        return PostColoredPattern.fromJson(json);
      }

      if (json is String) {
        // إذا كان string، قد يكون JSON مُرمز
        try {
          final decoded = jsonDecode(json);
          if (decoded is Map<String, dynamic>) {
            return PostColoredPattern.fromJson(decoded);
          }
        } catch (e) {
          // إذا فشل jsonDecode، قد يكون string عادي لمعرف النمط
          return PostColoredPattern(
            patternId: json,
            type: 'color', // افتراضي
            backgroundColors: const BackgroundColors(primary: '#6C5CE7'), // لون افتراضي
            textColor: '#FFFFFF',
          );
        }
      }

      if (json is int || json is double) {
        // إذا كان رقم 0، فلا يوجد نمط ملون
        if (json == 0) {
          return null;
        }
        // إذا كان رقم آخر، نعتبره معرف النمط
        return PostColoredPattern(
          patternId: json.toString(),
          type: 'color',
          backgroundColors: const BackgroundColors(primary: '#6C5CE7'), // لون افتراضي
          textColor: '#FFFFFF',
        );
      }

      return null;
    } catch (e) {
      // في حالة فشل الـ parsing، نعيد null
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': patternId,
      'pattern_id': patternId,
      'type': type,
      if (backgroundImage != null) 'background_image': backgroundImage!.toJson(),
      if (backgroundColors != null) 'background_colors': backgroundColors!.toJson(),
      if (textColor != null) 'text_color': textColor,
    };
  }

  PostColoredPattern copyWith({
    String? patternId,
    String? type,
    BackgroundImage? backgroundImage,
    BackgroundColors? backgroundColors,
    String? textColor,
  }) {
    return PostColoredPattern(
      patternId: patternId ?? this.patternId,
      type: type ?? this.type,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      backgroundColors: backgroundColors ?? this.backgroundColors,
      textColor: textColor ?? this.textColor,
    );
  }

  /// Check if this is an image-based pattern
  bool get isImagePattern => type == 'image' && backgroundImage != null;

  /// Check if this is a color-based pattern
  bool get isColorPattern => type == 'color' && backgroundColors != null;

  /// Check if this has a gradient (two colors)
  bool get hasGradient => backgroundColors?.secondary != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostColoredPattern &&
        other.patternId == patternId &&
        other.type == type &&
        other.backgroundImage == backgroundImage &&
        other.backgroundColors == backgroundColors &&
        other.textColor == textColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      patternId,
      type,
      backgroundImage,
      backgroundColors,
      textColor,
    );
  }

  @override
  String toString() {
    return 'PostColoredPattern(patternId: $patternId, type: $type, backgroundImage: $backgroundImage, backgroundColors: $backgroundColors, textColor: $textColor)';
  }
}
