import 'package:equatable/equatable.dart';
/// نموذج دعوة الفعالية (Event Invitation)
class EventInvitation extends Equatable {
  final int invitationId;
  final int eventId;
  final String eventTitle;
  final String? eventPicture;
  final DateTime eventStartDate;
  final DateTime eventEndDate;
  final String fromUserId;
  final String fromUserName;
  final String? fromFirstName;
  final String? fromLastName;
  final String? fromUserPicture;
  final DateTime invitedAt;
  final String status; // pending, accepted, rejected
  const EventInvitation({
    required this.invitationId,
    required this.eventId,
    required this.eventTitle,
    this.eventPicture,
    required this.eventStartDate,
    required this.eventEndDate,
    required this.fromUserId,
    required this.fromUserName,
    this.fromFirstName,
    this.fromLastName,
    this.fromUserPicture,
    required this.invitedAt,
    required this.status,
  });
  factory EventInvitation.fromJson(Map<String, dynamic> json) {
    return EventInvitation(
      invitationId: int.parse(json['invitation_id'].toString()),
      eventId: int.parse(json['event_id'].toString()),
      eventTitle: json['event_title'].toString(),
      eventPicture: json['event_picture']?.toString(),
      eventStartDate: DateTime.parse(json['event_start_date'].toString()),
      eventEndDate: DateTime.parse(json['event_end_date'].toString()),
      fromUserId: json['from_user_id'].toString(),
      fromUserName: json['from_user_name'].toString(),
      fromFirstName: json['from_user_firstname']?.toString(),
      fromLastName: json['from_user_lastname']?.toString(),
      fromUserPicture: json['from_user_picture']?.toString(),
      invitedAt: json['invited_at'] != null 
          ? DateTime.parse(json['invited_at'].toString())
          : DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'invitation_id': invitationId,
      'event_id': eventId,
      'event_title': eventTitle,
      'event_picture': eventPicture,
      'event_start_date': eventStartDate.toIso8601String(),
      'event_end_date': eventEndDate.toIso8601String(),
      'from_user_id': fromUserId,
      'from_user_name': fromUserName,
      'from_user_firstname': fromFirstName,
      'from_user_lastname': fromLastName,
      'from_user_picture': fromUserPicture,
      'invited_at': invitedAt.toIso8601String(),
      'status': status,
    };
  }
  String get fromUserFullName {
    if (fromFirstName == null && fromLastName == null) return fromUserName;
    return '${fromFirstName ?? ''} ${fromLastName ?? ''}'.trim();
  }
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  @override
  List<Object?> get props => [
        invitationId,
        eventId,
        eventTitle,
        eventPicture,
        eventStartDate,
        eventEndDate,
        fromUserId,
        fromUserName,
        fromFirstName,
        fromLastName,
        fromUserPicture,
        invitedAt,
        status,
      ];
}
