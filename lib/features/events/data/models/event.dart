import 'package:equatable/equatable.dart';

/// نموذج الفعالية (Event)
class Event extends Equatable {
  final int eventId;
  final String eventTitle;
  final String? eventDescription;
  final String? eventLocation;
  final String? eventPicture;
  final String? eventCover;
  final DateTime eventStartDate;
  final DateTime eventEndDate;
  final String eventPrivacy; // public, closed, secret
  final bool eventIsOnline;
  final int eventMembers;
  final int eventInterested;
  final int? categoryId;
  final String? categoryName;
  final int? countryId;
  final int? languageId;
  final bool iJoined;
  final bool iAdmin;
  final String? adminUserId;
  final String? adminUserName;
  final String? adminFirstName;
  final String? adminLastName;
  final String? adminPicture;

  const Event({
    required this.eventId,
    required this.eventTitle,
    this.eventDescription,
    this.eventLocation,
    this.eventPicture,
    this.eventCover,
    required this.eventStartDate,
    required this.eventEndDate,
    required this.eventPrivacy,
    required this.eventIsOnline,
    required this.eventMembers,
    required this.eventInterested,
    this.categoryId,
    this.categoryName,
    this.countryId,
    this.languageId,
    required this.iJoined,
    required this.iAdmin,
    this.adminUserId,
    this.adminUserName,
    this.adminFirstName,
    this.adminLastName,
    this.adminPicture,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Handle stats object if it exists
    final stats = json['stats'] as Map<String, dynamic>?;
    
    return Event(
      eventId: int.parse(json['event_id'].toString()),
      eventTitle: json['event_title'].toString(),
      eventDescription: json['event_description']?.toString(),
      eventLocation: json['event_location']?.toString(),
      eventPicture: json['event_picture']?.toString(),
      eventCover: json['event_cover']?.toString(),
      eventStartDate: DateTime.parse(json['event_start_date'].toString()),
      eventEndDate: DateTime.parse(json['event_end_date'].toString()),
      eventPrivacy: json['event_privacy']?.toString() ?? 'public',
      eventIsOnline: json['event_is_online'] == true || json['event_is_online'] == '1' || json['event_is_online'] == 1 || json['event_is_online'] == 'true',
      // Try stats.going first, fallback to event_members
      eventMembers: stats != null 
          ? int.parse(stats['going']?.toString() ?? '0')
          : int.parse(json['event_members']?.toString() ?? '0'),
      // Try stats.interested first, fallback to event_interested
      eventInterested: stats != null
          ? int.parse(stats['interested']?.toString() ?? '0')
          : int.parse(json['event_interested']?.toString() ?? '0'),
      // Try event_category_id first, fallback to category_id
      categoryId: json['event_category_id'] != null 
          ? int.tryParse(json['event_category_id'].toString())
          : (json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null),
      categoryName: json['category_name']?.toString(),
      countryId: json['event_country'] != null ? int.tryParse(json['event_country'].toString()) : null,
      languageId: json['event_language'] != null ? int.tryParse(json['event_language'].toString()) : null,
      iJoined: json['i_joined'] == true || json['i_joined'] == '1' || json['i_joined'] == 1 || json['i_joined'] == 'true',
      iAdmin: json['i_admin'] == true || json['i_admin'] == '1' || json['i_admin'] == 1 || json['i_admin'] == 'true',
      adminUserId: json['admin_user_id']?.toString(),
      adminUserName: json['admin_user_name']?.toString(),
      adminFirstName: json['admin_first_name']?.toString(),
      adminLastName: json['admin_last_name']?.toString(),
      adminPicture: json['admin_picture']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_title': eventTitle,
      'event_description': eventDescription,
      'event_location': eventLocation,
      'event_picture': eventPicture,
      'event_cover': eventCover,
      'event_start_date': eventStartDate.toIso8601String(),
      'event_end_date': eventEndDate.toIso8601String(),
      'event_privacy': eventPrivacy,
      'event_is_online': eventIsOnline,
      'event_members': eventMembers,
      'event_interested': eventInterested,
      'category_id': categoryId,
      'category_name': categoryName,
      'event_country': countryId,
      'event_language': languageId,
      'i_joined': iJoined,
      'i_admin': iAdmin,
      'admin_user_id': adminUserId,
      'admin_user_name': adminUserName,
      'admin_first_name': adminFirstName,
      'admin_last_name': adminLastName,
      'admin_picture': adminPicture,
    };
  }

  String get adminFullName {
    if (adminFirstName == null && adminLastName == null) return '';
    return '${adminFirstName ?? ''} ${adminLastName ?? ''}'.trim();
  }

  bool get isVerified => adminPicture != null && adminPicture!.isNotEmpty;

  @override
  List<Object?> get props => [
        eventId,
        eventTitle,
        eventDescription,
        eventLocation,
        eventPicture,
        eventCover,
        eventStartDate,
        eventEndDate,
        eventPrivacy,
        eventIsOnline,
        eventMembers,
        eventInterested,
        categoryId,
        categoryName,
        countryId,
        languageId,
        iJoined,
        iAdmin,
        adminUserId,
        adminUserName,
        adminFirstName,
        adminLastName,
        adminPicture,
      ];
}
