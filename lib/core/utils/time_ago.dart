import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

/// تحويل التاريخ والوقت إلى صيغة "منذ"
/// Converts datetime to "time ago" format
class TimeAgo {
  /// تحويل DateTime إلى صيغة "منذ" بالعربية
  static String formatArabic(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime.toLocal());

    if (difference.inSeconds < 60) {
      final seconds = difference.inSeconds;
      if (seconds < 5) {
        return 'just_now'.tr;
      } else if (seconds == 1) {
        return 'second_ago'.tr;
      } else if (seconds == 2) {
        return 'seconds_ago_2'.tr;
      } else if (seconds <= 10) {
        return 'seconds_ago_few'.trParams({'count': '$seconds'});
      } else {
        return 'seconds_ago'.trParams({'count': '$seconds'});
      }
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      if (minutes == 1) {
        return 'minute_ago'.tr;
      } else if (minutes == 2) {
        return 'minutes_ago_2'.tr;
      } else if (minutes <= 10) {
        return 'minutes_ago_few'.trParams({'count': '$minutes'});
      } else {
        return 'minutes_ago'.trParams({'count': '$minutes'});
      }
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (hours == 1) {
        return 'hour_ago'.tr;
      } else if (hours == 2) {
        return 'hours_ago_2'.tr;
      } else if (hours <= 10) {
        return 'hours_ago_few'.trParams({'count': '$hours'});
      } else {
        return 'hours_ago'.trParams({'count': '$hours'});
      }
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      if (days == 1) {
        return 'day_ago'.tr;
      } else if (days == 2) {
        return 'days_ago_2'.tr;
      } else if (days <= 10) {
        return 'days_ago_few'.trParams({'count': '$days'});
      } else {
        return 'days_ago'.trParams({'count': '$days'});
      }
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      if (weeks == 1) {
        return 'week_ago'.tr;
      } else if (weeks == 2) {
        return 'weeks_ago_2'.tr;
      } else if (weeks <= 10) {
        return 'weeks_ago_few'.trParams({'count': '$weeks'});
      } else {
        return 'weeks_ago'.trParams({'count': '$weeks'});
      }
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) {
        return 'month_ago'.tr;
      } else if (months == 2) {
        return 'months_ago_2'.tr;
      } else if (months <= 10) {
        return 'months_ago_few'.trParams({'count': '$months'});
      } else {
        return 'months_ago'.trParams({'count': '$months'});
      }
    } else {
      final years = (difference.inDays / 365).floor();
      if (years == 1) {
        return 'year_ago'.tr;
      } else if (years == 2) {
        return 'years_ago_2'.tr;
      } else if (years <= 10) {
        return 'years_ago_few'.trParams({'count': '$years'});
      } else {
        return 'years_ago'.trParams({'count': '$years'});
      }
    }
  }

  /// تحويل DateTime إلى صيغة "time ago" بالإنجليزية
  static String formatEnglish(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime.toLocal());

    if (difference.inSeconds < 60) {
      final seconds = difference.inSeconds;
      if (seconds < 5) {
        return 'just_now'.tr;
      }
      return seconds == 1 ? '1 ${'second_ago'.tr}' : '$seconds ${'seconds_ago'.tr}';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 ${'minute_ago'.tr}' : '$minutes ${'minutes_ago'.tr}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 ${'hour_ago'.tr}' : '$hours ${'hours_ago'.tr}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? '1 ${'day_ago'.tr}' : '$days ${'days_ago'.tr}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 ${'week_ago'.tr}' : '$weeks ${'weeks_ago'.tr}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 ${'month_ago'.tr}' : '$months ${'months_ago'.tr}';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 ${'year_ago'.tr}' : '$years ${'years_ago'.tr}';
    }
  }

  /// تحويل String datetime إلى صيغة "منذ" بالعربية
  /// يدعم الصيغ التالية:
  /// - ISO 8601 UTC: "2025-11-10T15:49:39Z" (الصيغة الموصى بها من الباك إند)
  /// - SQL datetime: "2025-11-10 15:49:39" (للتوافق مع البيانات القديمة)
  static String formatFromString(String? dateTimeString, {bool isEnglish = false}) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return isEnglish ? 'unknown' : 'غير معروف';
    }

    try {
      DateTime dateTime;
      
      // ISO 8601 with Z (UTC) - الصيغة الجديدة من الباك إند
      if (dateTimeString.contains('T')) {
        dateTime = DateTime.parse(dateTimeString);
      } 
      // SQL datetime - للتوافق مع البيانات القديمة
      // نعامله كـ UTC ثم نحوله للتوقيت المحلي
      else if (dateTimeString.contains(' ')) {
        dateTime = DateTime.parse(dateTimeString.replaceFirst(' ', 'T') + 'Z');
      } 
      // محاولة parse عادي
      else {
        dateTime = DateTime.parse(dateTimeString);
      }

      return isEnglish ? formatEnglish(dateTime) : formatArabic(dateTime);
    } catch (e) {
      return isEnglish ? 'unknown' : 'غير معروف';
    }
  }

  /// تحويل Unix timestamp (seconds) إلى صيغة "منذ"
  static String formatFromTimestamp(int timestamp, {bool isEnglish = false}) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return isEnglish ? formatEnglish(dateTime) : formatArabic(dateTime);
    } catch (e) {
      return isEnglish ? 'unknown' : 'غير معروف';
    }
  }

  /// تحويل Unix timestamp (milliseconds) إلى صيغة "منذ"
  static String formatFromMilliseconds(int milliseconds, {bool isEnglish = false}) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      return isEnglish ? formatEnglish(dateTime) : formatArabic(dateTime);
    } catch (e) {
      return isEnglish ? 'unknown' : 'غير معروف';
    }
  }
}