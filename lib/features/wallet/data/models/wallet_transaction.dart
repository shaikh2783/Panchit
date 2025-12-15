import 'package:equatable/equatable.dart';
class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.amountFormatted,
    required this.type,
    required this.direction,
    required this.label,
    required this.date,
    required this.timestamp,
    this.nodeType,
    this.nodeId,
    this.relatedUser,
    this.metadata,
  });
  final int id;
  final double amount;
  final String amountFormatted;
  final String type;
  final String direction;
  final String label;
  final String date;
  final int timestamp;
  final String? nodeType;
  final int? nodeId;
  final WalletRelatedUser? relatedUser;
  final Map<String, dynamic>? metadata;
  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: _toInt(json['transaction_id'] ?? json['id']),
      amount: _toDouble(json['amount'], fallback: 0),
      amountFormatted: _toString(json['amount_formatted']),
      type: _toString(json['type']),
      direction: _toString(json['direction']),
      label: _toString(json['label']),
      date: _toString(json['date']),
      timestamp: _toInt(json['timestamp']),
      nodeType: _nullableString(json['node_type']),
      nodeId: _nullableInt(json['node_id']),
      relatedUser: _parseRelatedUser(json['related_user']),
      metadata: _parseMetadata(json['metadata']),
    );
  }
  WalletTransaction copyWith({
    int? id,
    double? amount,
    String? amountFormatted,
    String? type,
    String? direction,
    String? label,
    String? date,
    int? timestamp,
    String? nodeType,
    int? nodeId,
    WalletRelatedUser? relatedUser,
    Map<String, dynamic>? metadata,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      amountFormatted: amountFormatted ?? this.amountFormatted,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      label: label ?? this.label,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      nodeType: nodeType ?? this.nodeType,
      nodeId: nodeId ?? this.nodeId,
      relatedUser: relatedUser ?? this.relatedUser,
      metadata: metadata ?? this.metadata,
    );
  }
  static WalletRelatedUser? _parseRelatedUser(Object? value) {
    if (value is Map<String, dynamic>) {
      return WalletRelatedUser.fromJson(value);
    }
    return null;
  }
  static Map<String, dynamic>? _parseMetadata(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }
  @override
  List<Object?> get props => [
    id,
    amount,
    amountFormatted,
    type,
    direction,
    label,
    date,
    timestamp,
    nodeType,
    nodeId,
    relatedUser,
    metadata,
  ];
}
class WalletRelatedUser extends Equatable {
  const WalletRelatedUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.picture,
    required this.verified,
  });
  final int id;
  final String username;
  final String fullName;
  final String picture;
  final bool verified;
  factory WalletRelatedUser.fromJson(Map<String, dynamic> json) {
    return WalletRelatedUser(
      id: _toInt(json['user_id'] ?? json['id']),
      username: _toString(json['user_name'] ?? json['username']),
      fullName: _toString(json['full_name'] ?? json['name']),
      picture: _toString(json['picture'] ?? json['avatar']),
      verified: _toBool(json['verified'] ?? json['is_verified']),
    );
  }
  WalletRelatedUser copyWith({
    int? id,
    String? username,
    String? fullName,
    String? picture,
    bool? verified,
  }) {
    return WalletRelatedUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      picture: picture ?? this.picture,
      verified: verified ?? this.verified,
    );
  }
  @override
  List<Object?> get props => [id, username, fullName, picture, verified];
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
int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value);
  }
  return null;
}
bool _toBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == '1' || lower == 'true' || lower == 'yes' || lower == 'on';
  }
  return false;
}
