import 'package:equatable/equatable.dart';

class WalletPayment extends Equatable {
  const WalletPayment({
    required this.id,
    required this.amount,
    required this.amountFormatted,
    required this.method,
    required this.methodValue,
    required this.status,
    required this.statusCode,
    required this.requestedAt,
    required this.timestamp,
    this.notes,
  });

  final int id;
  final double amount;
  final String amountFormatted;
  final String method;
  final String methodValue;
  final String status;
  final int statusCode;
  final String requestedAt;
  final int timestamp;
  final String? notes;

  factory WalletPayment.fromJson(Map<String, dynamic> json) {
    return WalletPayment(
      id: _toInt(json['payment_id'] ?? json['id']),
      amount: _toDouble(json['amount'], fallback: 0),
      amountFormatted: _toString(json['amount_formatted']),
      method: _toString(json['method']),
      methodValue: _toString(json['method_value']),
      status: _toString(json['status']),
      statusCode: _toInt(json['status_code']),
      requestedAt: _toString(json['requested_at'] ?? json['created_at']),
      timestamp: _toInt(json['timestamp']),
      notes: _nullableString(json['notes']),
    );
  }

  WalletPayment copyWith({
    int? id,
    double? amount,
    String? amountFormatted,
    String? method,
    String? methodValue,
    String? status,
    int? statusCode,
    String? requestedAt,
    int? timestamp,
    String? notes,
  }) {
    return WalletPayment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      amountFormatted: amountFormatted ?? this.amountFormatted,
      method: method ?? this.method,
      methodValue: methodValue ?? this.methodValue,
      status: status ?? this.status,
      statusCode: statusCode ?? this.statusCode,
      requestedAt: requestedAt ?? this.requestedAt,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    amountFormatted,
    method,
    methodValue,
    status,
    statusCode,
    requestedAt,
    timestamp,
    notes,
  ];
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

double _toDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _toString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final stringValue = value.toString();
  return stringValue.isEmpty ? null : stringValue;
}
