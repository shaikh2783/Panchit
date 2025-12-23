import 'dart:collection';
import 'watch_item.dart';

class WatchResponse {
  WatchResponse({
    required this.status,
    required List<WatchItem> items,
    required this.hasMore,
    this.message,
    this.minResults,
  }) : items = UnmodifiableListView(items);

  final String status;
  final UnmodifiableListView<WatchItem> items;
  final bool hasMore;
  final String? message;
  final int? minResults;

  bool get isSuccess => status.toLowerCase() == 'success';

  factory WatchResponse.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String?) ?? 'error';
    final data = json['data'];
    final minResults = json['min_results'] is int ? json['min_results'] as int : int.tryParse('${json['min_results'] ?? ''}');
    final hasMoreFlag = json['has_more'] == true || json['has_more'] == 1 || json['has_more'] == '1';

    List<dynamic> listRaw = [];
    if (data is List) {
      listRaw = data;
    } else if (data is Map && data['items'] is List) {
      listRaw = data['items'] as List;
    }

    final items = listRaw.whereType<Map<String, dynamic>>()
        .map(WatchItem.fromJson)
        .toList();

    bool hasMore;
    if (json.containsKey('has_more')) {
      hasMore = hasMoreFlag;
      if (!hasMore && (minResults != null) && items.isNotEmpty) {
        hasMore = items.length >= (minResults);
      }
    } else {
      hasMore = minResults != null ? items.length >= minResults : items.isNotEmpty;
    }

    return WatchResponse(
      status: status,
      items: items,
      hasMore: hasMore,
      message: json['message'] as String?,
      minResults: minResults,
    );
  }
}
