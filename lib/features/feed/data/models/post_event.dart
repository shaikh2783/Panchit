class PostEvent {
  final String eventId;
  final String eventTitle;
  final String? eventDescription;
  final String? eventLocation;
  final String eventStartDate;
  final String eventEndDate;
  final bool eventIsOnline;
  final String? eventCover;
  final int eventInterested;
  final int eventGoing;
  final bool iJoined;
  const PostEvent({
    required this.eventId,
    required this.eventTitle,
    this.eventDescription,
    this.eventLocation,
    required this.eventStartDate,
    required this.eventEndDate,
    required this.eventIsOnline,
    this.eventCover,
    required this.eventInterested,
    required this.eventGoing,
    required this.iJoined,
  });
  factory PostEvent.fromJson(Map<String, dynamic> json) {
    // Handle i_joined format from API response
    bool iJoined = false;
    if (json['i_joined'] is Map<String, dynamic>) {
      final iJoinedData = json['i_joined'] as Map<String, dynamic>;
      // Check if user is interested or going
      iJoined = (iJoinedData['is_interested']?.toString() == '1') || 
               (iJoinedData['is_going']?.toString() == '1');
    } else {
      iJoined = json['i_joined'] == true || json['i_joined']?.toString() == '1';
    }
    return PostEvent(
      eventId: json['event_id']?.toString() ?? '0',
      eventTitle: json['event_title']?.toString() ?? '',
      eventDescription: json['event_description']?.toString(),
      eventLocation: json['event_location']?.toString(),
      eventStartDate: json['event_start_date']?.toString() ?? '',
      eventEndDate: json['event_end_date']?.toString() ?? '',
      eventIsOnline: json['event_is_online']?.toString() == '1',
      eventCover: json['event_cover']?.toString(),
      eventInterested: int.tryParse(json['event_interested']?.toString() ?? 
                                  json['event_interested_formatted']?.toString() ?? '0') ?? 0,
      eventGoing: int.tryParse(json['event_going']?.toString() ?? '0') ?? 0,
      iJoined: iJoined,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_title': eventTitle,
      'event_description': eventDescription,
      'event_location': eventLocation,
      'event_start_date': eventStartDate,
      'event_end_date': eventEndDate,
      'event_is_online': eventIsOnline ? '1' : '0',
      'event_cover': eventCover,
      'event_interested': eventInterested,
      'event_going': eventGoing,
      'i_joined': iJoined,
    };
  }
  PostEvent copyWith({
    String? eventId,
    String? eventTitle,
    String? eventDescription,
    String? eventLocation,
    String? eventStartDate,
    String? eventEndDate,
    bool? eventIsOnline,
    String? eventCover,
    int? eventInterested,
    int? eventGoing,
    bool? iJoined,
  }) {
    return PostEvent(
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDescription: eventDescription ?? this.eventDescription,
      eventLocation: eventLocation ?? this.eventLocation,
      eventStartDate: eventStartDate ?? this.eventStartDate,
      eventEndDate: eventEndDate ?? this.eventEndDate,
      eventIsOnline: eventIsOnline ?? this.eventIsOnline,
      eventCover: eventCover ?? this.eventCover,
      eventInterested: eventInterested ?? this.eventInterested,
      eventGoing: eventGoing ?? this.eventGoing,
      iJoined: iJoined ?? this.iJoined,
    );
  }
  // Helper getters
  String get formattedInterestedCount => _formatCount(eventInterested);
  String get formattedGoingCount => _formatCount(eventGoing);
  static String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}