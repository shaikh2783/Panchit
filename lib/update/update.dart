import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

// Model للتحديث
class UpdateInfo {
  final String appName;
  final String latestVersion;
  final int buildNumber;
  final bool forceUpdate;
  final bool updateAvailable;
  final String updateUrl;
  final String messageAr;
  final String messageEn;
  final List<String> changelogAr;
  final List<String> changelogEn;
  final String releaseDate;

  UpdateInfo({
    required this.appName,
    required this.latestVersion,
    required this.buildNumber,
    required this.forceUpdate,
    required this.updateAvailable,
    required this.updateUrl,
    required this.messageAr,
    required this.messageEn,
    required this.changelogAr,
    required this.changelogEn,
    required this.releaseDate,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    final changelog = json['changelog'] as Map<String, dynamic>? ?? {};
    final changelogArRaw = changelog['ar'];
    final changelogEnRaw = changelog['en'];

    final hasUpdateAvailableFlag = json.containsKey('update_available');
    final updateAvailable =
        hasUpdateAvailableFlag ? (json['update_available'] ?? false) : true;

    return UpdateInfo(
      appName: json['app_name'] ?? 'Panchit',
      latestVersion: json['latest_version'] ?? '',
      buildNumber: json['build_number'] ?? 0,
      forceUpdate: json['force_update'] ?? false,
      updateAvailable: updateAvailable,
      updateUrl: json['update_url'] ?? '',
      messageAr: json['message_ar'] ?? '',
      messageEn: json['message_en'] ?? '',
      changelogAr: changelogArRaw is List
          ? List<String>.from(changelogArRaw)
          : const [],
      changelogEn: changelogEnRaw is List
          ? List<String>.from(changelogEnRaw)
          : const [],
      releaseDate: json['release_date'] ?? '',
    );
  }
}

// Service لفحص التحديث
class UpdateService {
  static const String updateUrl =
      'https://www.panchit.com/apis/php/data/app/version';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(updateUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UpdateInfo.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isUpdateAvailable() async {
    try {
      final updateInfo = await checkForUpdate();
      if (updateInfo == null) return false;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      return updateInfo.updateAvailable &&
          updateInfo.buildNumber > currentBuildNumber;
    } catch (e) {
      return false;
    }
  }

  static Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// Widget لعرض dialog التحديث
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final bool isArabic;

  const UpdateDialog({Key? key, required this.updateInfo, this.isArabic = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message = isArabic ? updateInfo.messageAr : updateInfo.messageEn;
    final changelog = isArabic
        ? updateInfo.changelogAr
        : updateInfo.changelogEn;
    final isDark = Get.isDarkMode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    const Color(0xFF1E1E1E),
                  ]
                : [
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    Colors.white,
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header مع أيقونة
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.system_update_alt,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'تحديث جديد متاح!' : 'New Update Available!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${isArabic ? "الإصدار" : "Version"} ${updateInfo.latestVersion}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رسالة التحديث
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                            : Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Changelog
                  Text(
                    isArabic ? 'ما الجديد:' : 'What\'s New:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...changelog.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // تاريخ الإصدار
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isArabic ? "تاريخ الإصدار" : "Release Date"}: ${updateInfo.releaseDate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // زر التحديث
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        UpdateService.launchUpdateUrl(updateInfo.updateUrl);
                        if (!updateInfo.forceUpdate) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: isDark ? 4 : 2,
                        shadowColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(isDark ? 0.7 : 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.download, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'تحديث الآن' : 'Update Now',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // زر لاحقاً (إذا لم يكن إجباري)
                  if (!updateInfo.forceUpdate) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isArabic ? 'لاحقاً' : 'Later',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Function رئيسية لفحص وعرض التحديث
Future<void> checkAndShowUpdate(
  BuildContext context, {
  bool isArabic = true,
  bool showOnlyIfAvailable = true,
}) async {
  try {
    final updateInfo = await UpdateService.checkForUpdate();

    if (updateInfo == null) {
      if (!showOnlyIfAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'فشل فحص التحديث' : 'Failed to check for updates',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final isUpdateAvailable =
        updateInfo.updateAvailable &&
        updateInfo.buildNumber > currentBuildNumber;

    if (isUpdateAvailable) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: !updateInfo.forceUpdate,
          builder: (context) => WillPopScope(
            onWillPop: () async => !updateInfo.forceUpdate,
            child: UpdateDialog(updateInfo: updateInfo, isArabic: isArabic),
          ),
        );
      }
    } else if (!showOnlyIfAvailable) {
      if (context.mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(
        //       isArabic
        //         ? 'أنت تستخدم أحدث إصدار'
        //         : 'You are using the latest version',
        //     ),
        //     backgroundColor: Colors.green,
        //     behavior: SnackBarBehavior.floating,
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(10),
        //     ),
        //   ),
        // );
      }
    }
  } catch (e) {
    if (!showOnlyIfAvailable && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'حدث خطأ أثناء فحص التحديث'
                : 'An error occurred while checking for updates',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Widget للتحقق التلقائي من التحديث
class AutoUpdateChecker extends StatefulWidget {
  final Widget child;
  final bool isArabic;
  final Duration checkInterval;

  const AutoUpdateChecker({
    Key? key,
    required this.child,
    this.isArabic = true,
    this.checkInterval = const Duration(hours: 24),
  }) : super(key: key);

  @override
  State<AutoUpdateChecker> createState() => _AutoUpdateCheckerState();
}

class _AutoUpdateCheckerState extends State<AutoUpdateChecker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (mounted) {
      await checkAndShowUpdate(
        context,
        isArabic: widget.isArabic,
        showOnlyIfAvailable: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
