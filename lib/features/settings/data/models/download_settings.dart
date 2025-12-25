class DownloadOption {
  final String label;
  final String description;

  DownloadOption({required this.label, required this.description});

  factory DownloadOption.fromJson(Map<String, dynamic> json) {
    return DownloadOption(
      label: json['label'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class DownloadSettings {
  final bool downloadEnabled;
  final bool isDemoAccount;
  final Map<String, DownloadOption> availableOptions;

  DownloadSettings({
    required this.downloadEnabled,
    required this.isDemoAccount,
    required this.availableOptions,
  });

  factory DownloadSettings.fromJson(Map<String, dynamic> json) {
    Map<String, DownloadOption> options = {};

    if (json['available_options'] != null) {
      (json['available_options'] as Map<String, dynamic>).forEach((key, value) {
        options[key] = DownloadOption.fromJson(value);
      });
    }

    return DownloadSettings(
      downloadEnabled: _toBool(json['download_enabled']),
      isDemoAccount: _toBool(json['is_demo_account']),
      availableOptions: options,
    );
  }

  List<String> get availableKeys => availableOptions.keys.toList();

  String getLabel(String key) => availableOptions[key]?.label ?? '';
  String getDescription(String key) => availableOptions[key]?.description ?? '';

  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == '1' || lower == 'true' || lower == 'yes';
    }
    return fallback;
  }
}
