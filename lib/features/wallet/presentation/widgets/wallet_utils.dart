import 'package:flutter/material.dart';

Color walletStatusColor(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('pending')) {
    return Colors.orange;
  }
  if (lower.contains('reject') || lower.contains('cancel')) {
    return Colors.red;
  }
  if (lower.contains('complete') ||
      lower.contains('paid') ||
      lower.contains('approved')) {
    return Colors.green;
  }
  return Colors.blueGrey;
}

String walletFormatDate(DateTime date) {
  final local = date.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

DateTime walletDateTimeFromTimestamp(int timestamp) {
  if (timestamp == 0) {
    return DateTime.now();
  }
  if (timestamp > 1000000000000) {
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp,
      isUtc: true,
    ).toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(
    timestamp * 1000,
    isUtc: true,
  ).toLocal();
}
