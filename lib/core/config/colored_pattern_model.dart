/// نموذج البيانات للخلفيات الملونة  
class ColoredPattern {
  final int id;
  final String type; // 'image' or 'color'
  final String textColor;
  final BackgroundImage? backgroundImage;
  final BackgroundColors? backgroundColors;

  const ColoredPattern({
    required this.id,
    required this.type,
    required this.textColor,
    this.backgroundImage,
    this.backgroundColors,
  });

  factory ColoredPattern.fromJson(Map<String, dynamic> json) {
    return ColoredPattern(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? 'color',
      textColor: json['text_color']?.toString() ?? '#FFFFFF',
      backgroundImage: json['background_image'] != null 
          ? BackgroundImage.fromJson(json['background_image'])
          : null,
      backgroundColors: json['background_colors'] != null
          ? BackgroundColors.fromJson(json['background_colors'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'text_color': textColor,
      if (backgroundImage != null) 'background_image': backgroundImage!.toJson(),
      if (backgroundColors != null) 'background_colors': backgroundColors!.toJson(),
    };
  }

  /// Check if this is an image-based pattern
  bool get isImagePattern => type == 'image' && backgroundImage != null;

  /// Check if this is a color-based pattern  
  bool get isColorPattern => type == 'color' && backgroundColors != null;

  /// Check if this has a gradient (two colors)
  bool get hasGradient => backgroundColors?.secondary != null;
}

/// صورة الخلفية
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
}

/// ألوان الخلفية
class BackgroundColors {
  final String primary;
  final String? secondary;

  const BackgroundColors({
    required this.primary,
    this.secondary,
  });

  factory BackgroundColors.fromJson(Map<String, dynamic> json) {
    return BackgroundColors(
      primary: json['primary']?.toString() ?? '#1877f2',
      secondary: json['secondary']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      if (secondary != null) 'secondary': secondary,
    };
  }
}