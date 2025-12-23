import 'dart:collection';
import 'person.dart';

class PeopleResponse {
  PeopleResponse({
    required this.status,
    required List<Person> people,
    required this.hasMore,
    this.message,
    this.minResults,
  }) : people = UnmodifiableListView(people);

  final String status;
  final UnmodifiableListView<Person> people;
  final bool hasMore;
  final String? message;
  final int? minResults;

  bool get isSuccess => status.toLowerCase() == 'success';

  factory PeopleResponse.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String?) ?? 'error';
    final data = json['data'];
    final minResults = json['min_results'] is int ? json['min_results'] as int : int.tryParse('${json['min_results'] ?? ''}');
    final hasMoreFlag = json['has_more'] == true || json['has_more'] == 1 || json['has_more'] == '1';

    List<dynamic> listRaw = [];
    if (data is List) {
      listRaw = data;
    } else if (data is Map && data['people'] is List) {
      listRaw = data['people'] as List;
    }

    final people = listRaw.whereType<Map<String, dynamic>>()
        .map(Person.fromJson)
        .toList();

    bool hasMore;
    if (json.containsKey('has_more')) {
      hasMore = hasMoreFlag;
      if (!hasMore && (minResults != null) && people.isNotEmpty) {
        // Be optimistic if backend misreports has_more
        hasMore = people.length >= (minResults);
      }
    } else {
      hasMore = minResults != null ? people.length >= minResults : people.isNotEmpty;
    }

    return PeopleResponse(
      status: status,
      people: people,
      hasMore: hasMore,
      message: json['message'] as String?,
      minResults: minResults,
    );
  }
}
