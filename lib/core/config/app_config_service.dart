import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for handling app configuration including feelings and activities
class AppConfigService {
  final String baseUrl;
  final String token;
  
  AppConfigService({required this.baseUrl, required this.token});
  
  /// Get complete app configuration
  Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data/app/config'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        return result;
      } else {

        return {'status': 'error', 'message': 'Failed to get config'};
      }
    } catch (e) {

      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  /// Get feelings for UI dropdown
  Future<List<FeelingsItem>> getFeelings() async {
    try {
      final config = await getAppConfig();
      if (config['status'] == 'success' && 
          config['data'] != null && 
          config['data']['features'] != null &&
          config['data']['features']['posts'] != null &&
          config['data']['features']['posts']['feelings'] == true) {
        
        final feelingsList = config['data']['feelings'] as List<dynamic>? ?? [];
        return feelingsList.map((item) => FeelingsItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {

      return [];
    }
  }
  
  /// Get activities/emotions for UI dropdown
  Future<List<ActivitiesItem>> getActivities() async {
    try {
      final config = await getAppConfig();
      if (config['status'] == 'success' && 
          config['data'] != null && 
          config['data']['features'] != null &&
          config['data']['features']['posts'] != null &&
          config['data']['features']['posts']['feelings'] == true) {
        
        final activitiesList = config['data']['activities'] as List<dynamic>? ?? [];
        return activitiesList.map((item) => ActivitiesItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {

      return [];
    }
  }
  
  /// Check if feelings are enabled in the system
  Future<bool> areFeelingsEnabled() async {
    try {
      final config = await getAppConfig();
      if (config['status'] == 'success' && config['data'] != null) {
        return config['data']['features']?['posts']?['feelings'] ?? false;
      }
      return false;
    } catch (e) {

      return false;
    }
  }
  
  /// Get colored patterns for posts
  Future<List<ColoredPattern>> getColoredPatterns() async {
    try {
      final config = await getAppConfig();
      if (config['status'] == 'success' && config['data'] != null) {
        final patternsList = config['data']['colored_patterns'] as List<dynamic>? ?? [];
        return patternsList.map((item) => ColoredPattern.fromJson(item)).toList();
      }
      return [];
    } catch (e) {

      return [];
    }
  }
}

/// Model for feelings data from API
class FeelingsItem {
  final String icon;
  final String action;
  final String text;
  final String placeholder;
  
  FeelingsItem({
    required this.icon,
    required this.action,
    required this.text,
    required this.placeholder,
  });
  
  factory FeelingsItem.fromJson(Map<String, dynamic> json) => FeelingsItem(
    icon: json['icon'] ?? '',
    action: json['action'] ?? '',
    text: json['text'] ?? '',
    placeholder: json['placeholder'] ?? '',
  );
  
  Map<String, dynamic> toJson() => {
    'icon': icon,
    'action': action,
    'text': text,
    'placeholder': placeholder,
  };
}

/// Model for activities/emotions data from API
class ActivitiesItem {
  final String icon;
  final String action;
  final String text;
  final String type;
  
  ActivitiesItem({
    required this.icon,
    required this.action,
    required this.text,
    required this.type,
  });
  
  factory ActivitiesItem.fromJson(Map<String, dynamic> json) => ActivitiesItem(
    icon: json['icon'] ?? '',
    action: json['action'] ?? '',
    text: json['text'] ?? '',
    type: json['type'] ?? 'emotion',
  );
  
  Map<String, dynamic> toJson() => {
    'icon': icon,
    'action': action,
    'text': text,
    'type': type,
  };
}

/// Model for colored patterns
class ColoredPattern {
  final int id;
  final String type;
  final String textColor;
  final Map<String, String> backgroundColors;
  
  ColoredPattern({
    required this.id,
    required this.type,
    required this.textColor,
    required this.backgroundColors,
  });
  
  factory ColoredPattern.fromJson(Map<String, dynamic> json) => ColoredPattern(
    id: json['id'] ?? 0,
    type: json['type'] ?? 'color',
    textColor: json['text_color'] ?? '#FFFFFF',
    backgroundColors: Map<String, String>.from(json['background_colors'] ?? {}),
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'text_color': textColor,
    'background_colors': backgroundColors,
  };
}