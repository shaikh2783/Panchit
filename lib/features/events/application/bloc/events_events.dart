import 'package:equatable/equatable.dart';
/// Events أحداث
abstract class EventsEvent extends Equatable {
  const EventsEvent();
  @override
  List<Object?> get props => [];
}
/// جلب فعاليات مقترحة
class FetchSuggestedEventsEvent extends EventsEvent {
  final int? categoryId;
  final String? type;
  final String? country;
  final bool refresh;
  const FetchSuggestedEventsEvent({
    this.categoryId,
    this.type,
    this.country,
    this.refresh = false,
  });
  @override
  List<Object?> get props => [categoryId, type, country, refresh];
}
/// جلب فعالياتي
class FetchMyEventsEvent extends EventsEvent {
  final String? filter;
  final bool refresh;
  const FetchMyEventsEvent({
    this.filter,
    this.refresh = false,
  });
  @override
  List<Object?> get props => [filter, refresh];
}
/// البحث عن فعاليات
class SearchEventsEvent extends EventsEvent {
  final String query;
  const SearchEventsEvent(this.query);
  @override
  List<Object?> get props => [query];
}
/// جلب تفاصيل فعالية
class FetchEventDetailsEvent extends EventsEvent {
  final int eventId;
  const FetchEventDetailsEvent(this.eventId);
  @override
  List<Object?> get props => [eventId];
}
/// جلب تصنيفات الفعاليات
class FetchEventCategoriesEvent extends EventsEvent {
  const FetchEventCategoriesEvent();
  @override
  List<Object?> get props => [];
}
/// إنشاء فعالية
class CreateEventEvent extends EventsEvent {
  final String title;
  final String location;
  final String description;
  final int categoryId;
  final String startDate;
  final String endDate;
  final String privacy;
  final bool isOnline;
  final int? country;
  final int? language;
  final String? eventPicture;
  final String? eventCover;
  const CreateEventEvent({
    required this.title,
    required this.location,
    required this.description,
    required this.categoryId,
    required this.startDate,
    required this.endDate,
    required this.privacy,
    required this.isOnline,
    this.country,
    this.language,
    this.eventPicture,
    this.eventCover,
  });
  @override
  List<Object?> get props => [
        title,
        location,
        description,
        categoryId,
        startDate,
        endDate,
        privacy,
        isOnline,
        country,
        language,
        eventPicture,
        eventCover,
      ];
}
/// تعديل فعالية
class UpdateEventEvent extends EventsEvent {
  final int eventId;
  final String? title;
  final String? description;
  final String? location;
  final int? categoryId;
  final String? startDate;
  final String? endDate;
  final String? privacy;
  final bool? isOnline;
  final int? country;
  final int? language;
  final String? eventPicture;
  final String? eventCover;
  const UpdateEventEvent({
    required this.eventId,
    this.title,
    this.description,
    this.location,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.privacy,
    this.isOnline,
    this.country,
    this.language,
    this.eventPicture,
    this.eventCover,
  });
  @override
  List<Object?> get props => [
        eventId,
        title,
        description,
        location,
        categoryId,
        startDate,
        endDate,
        privacy,
        isOnline,
        country,
        language,
        eventPicture,
        eventCover,
      ];
}
/// حذف فعالية
class DeleteEventEvent extends EventsEvent {
  final int eventId;
  const DeleteEventEvent(this.eventId);
  @override
  List<Object?> get props => [eventId];
}
/// الانضمام لفعالية
class JoinEventEvent extends EventsEvent {
  final int eventId;
  final String action; // going, interested
  const JoinEventEvent({
    required this.eventId,
    this.action = 'going',
  });
  @override
  List<Object?> get props => [eventId, action];
}
/// مغادرة فعالية
class LeaveEventEvent extends EventsEvent {
  final int eventId;
  const LeaveEventEvent(this.eventId);
  @override
  List<Object?> get props => [eventId];
}
/// جلب أعضاء فعالية
class FetchEventMembersEvent extends EventsEvent {
  final int eventId;
  final String? type;
  final bool refresh;
  const FetchEventMembersEvent({
    required this.eventId,
    this.type,
    this.refresh = false,
  });
  @override
  List<Object?> get props => [eventId, type, refresh];
}
/// دعوة أصدقاء
class InviteFriendsToEventEvent extends EventsEvent {
  final int eventId;
  final List<int> userIds;
  const InviteFriendsToEventEvent({
    required this.eventId,
    required this.userIds,
  });
  @override
  List<Object?> get props => [eventId, userIds];
}
/// جلب منشورات فعالية
class FetchEventPostsEvent extends EventsEvent {
  final int eventId;
  final bool refresh;
  const FetchEventPostsEvent({
    required this.eventId,
    this.refresh = false,
  });
  @override
  List<Object?> get props => [eventId, refresh];
}
/// تحديث صورة الفعالية
class UpdateEventPictureEvent extends EventsEvent {
  final int eventId;
  final String pictureData; // base64 or URL
  const UpdateEventPictureEvent({
    required this.eventId,
    required this.pictureData,
  });
  @override
  List<Object?> get props => [eventId, pictureData];
}
/// تحديث غلاف الفعالية
class UpdateEventCoverEvent extends EventsEvent {
  final int eventId;
  final String coverData; // base64 or URL
  const UpdateEventCoverEvent({
    required this.eventId,
    required this.coverData,
  });
  @override
  List<Object?> get props => [eventId, coverData];
}
