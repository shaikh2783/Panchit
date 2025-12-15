import 'package:equatable/equatable.dart';
class WalletPaginatedResult<T> extends Equatable {
  const WalletPaginatedResult({
    required this.items,
    required this.count,
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
    this.raw,
  });
  final List<T> items;
  final int count;
  final int total;
  final int offset;
  final int limit;
  final bool hasMore;
  final Map<String, dynamic>? raw;
  WalletPaginatedResult<T> copyWith({
    List<T>? items,
    int? count,
    int? total,
    int? offset,
    int? limit,
    bool? hasMore,
    Map<String, dynamic>? raw,
  }) {
    return WalletPaginatedResult<T>(
      items: items ?? this.items,
      count: count ?? this.count,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      raw: raw ?? this.raw,
    );
  }
  @override
  List<Object?> get props => [items, count, total, offset, limit, hasMore, raw];
  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
  static bool _toBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == '1' || lower == 'true';
    }
    return false;
  }
  static Map<String, dynamic> _map(Object? source) {
    if (source is Map<String, dynamic>) {
      return source;
    }
    return const {};
  }
  static WalletPaginatedResult<T> fromJson<T>(
    Map<String, dynamic> json, {
    required String itemsKey,
    required T Function(Map<String, dynamic>) itemBuilder,
  }) {
    final data = _map(json['data']);
    final itemsJson = data[itemsKey];
    final List<T> items;
    if (itemsJson is List) {
      items = itemsJson
          .whereType<Map<String, dynamic>>()
          .map(itemBuilder)
          .toList();
    } else {
      items = const [];
    }
    return WalletPaginatedResult<T>(
      items: items,
      count: _toInt(data['count']),
      total: _toInt(data['total']),
      offset: _toInt(data['offset']),
      limit: _toInt(data['limit']),
      hasMore: _toBool(data['has_more']),
      raw: data.isEmpty ? null : data,
    );
  }
}
