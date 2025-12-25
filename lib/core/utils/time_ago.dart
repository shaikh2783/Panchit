/// تحويل التاريخ والوقت إلى صيغة "منذ"
/// Converts datetime to "time ago" format
class TimeAgo {
  /// تحويل DateTime إلى صيغة "منذ" بالعربية
  static String formatArabic(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'منذ لحظات';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      if (minutes == 1) {
        return 'منذ دقيقة';
      } else if (minutes == 2) {
        return 'منذ دقيقتين';
      } else if (minutes <= 10) {
        return 'منذ $minutes دقائق';
      } else {
        return 'منذ $minutes دقيقة';
      }
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (hours == 1) {
        return 'منذ ساعة';
      } else if (hours == 2) {
        return 'منذ ساعتين';
      } else if (hours <= 10) {
        return 'منذ $hours ساعات';
      } else {
        return 'منذ $hours ساعة';
      }
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      if (days == 1) {
        return 'منذ يوم';
      } else if (days == 2) {
        return 'منذ يومين';
      } else if (days <= 10) {
        return 'منذ $days أيام';
      } else {
        return 'منذ $days يوماً';
      }
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      if (weeks == 1) {
        return 'منذ أسبوع';
      } else if (weeks == 2) {
        return 'منذ أسبوعين';
      } else if (weeks <= 10) {
        return 'منذ $weeks أسابيع';
      } else {
        return 'منذ $weeks أسبوعاً';
      }
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) {
        return 'منذ شهر';
      } else if (months == 2) {
        return 'منذ شهرين';
      } else if (months <= 10) {
        return 'منذ $months أشهر';
      } else {
        return 'منذ $months شهراً';
      }
    } else {
      final years = (difference.inDays / 365).floor();
      if (years == 1) {
        return 'منذ سنة';
      } else if (years == 2) {
        return 'منذ سنتين';
      } else if (years <= 10) {
        return 'منذ $years سنوات';
      } else {
        return 'منذ $years سنة';
      }
    }
  }

  /// تحويل DateTime إلى صيغة "time ago" بالإنجليزية
  static String formatEnglish(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? '1 day ago' : '$days days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  /// تحويل String datetime إلى صيغة "منذ" بالعربية
  /// يدعم الصيغ التالية:
  /// - ISO 8601: "2025-11-10T15:49:39Z"
  /// - SQL datetime: "2025-11-10 15:49:39"
  static String formatFromString(String? dateTimeString, {bool isEnglish = false}) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return isEnglish ? 'unknown' : 'غير معروف';
    }

    try {
      DateTime dateTime;
      
      // إذا كان String يحتوي على "T" فهو ISO 8601
      if (dateTimeString.contains('T')) {
        dateTime = DateTime.parse(dateTimeString);
      } 
      // إذا كان يحتوي على مسافة فهو SQL datetime
      else if (dateTimeString.contains(' ')) {
        dateTime = DateTime.parse(dateTimeString.replaceFirst(' ', 'T'));
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
