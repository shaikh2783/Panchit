import 'package:equatable/equatable.dart';
import '../../data/models/event.dart';
import '../../data/models/event_member.dart';
import '../../data/models/event_category.dart';

/// Events حالات
abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class EventsInitial extends EventsState {}

/// جاري التحميل
class EventsLoading extends EventsState {}

/// نجح تحميل الفعاليات المقترحة
class SuggestedEventsLoaded extends EventsState {
  final List<Event> events;
  final int total;
  final bool hasMore;

  const SuggestedEventsLoaded({
    required this.events,
    required this.total,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [events, total, hasMore];
}

/// نجح تحميل فعالياتي
class MyEventsLoaded extends EventsState {
  final List<Event> events;
  final int total;
  final bool hasMore;

  const MyEventsLoaded({
    required this.events,
    required this.total,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [events, total, hasMore];
}

/// نجح البحث عن فعاليات
class EventsSearchResultsLoaded extends EventsState {
  final List<Event> events;
  final String query;
  final int total;

  const EventsSearchResultsLoaded({
    required this.events,
    required this.query,
    required this.total,
  });

  @override
  List<Object?> get props => [events, query, total];
}

/// نجح تحميل تفاصيل فعالية
class EventDetailsLoaded extends EventsState {
  final Event event;

  const EventDetailsLoaded(this.event);

  @override
  List<Object?> get props => [event];
}

/// نجح إنشاء فعالية
class EventCreated extends EventsState {
  final int eventId;
  final String message;

  const EventCreated({
    required this.eventId,
    required this.message,
  });

  @override
  List<Object?> get props => [eventId, message];
}

/// نجح تحديث فعالية
class EventUpdated extends EventsState {
  final String message;

  const EventUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

/// نجح حذف فعالية
class EventDeleted extends EventsState {
  final String message;

  const EventDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

/// نجح الانضمام لفعالية
class EventJoined extends EventsState {
  final int eventId;
  final String status;
  final String message;

  const EventJoined({
    required this.eventId,
    required this.status,
    required this.message,
  });

  @override
  List<Object?> get props => [eventId, status, message];
}

/// نجحت مغادرة فعالية
class EventLeft extends EventsState {
  final int eventId;
  final String message;

  const EventLeft({
    required this.eventId,
    required this.message,
  });

  @override
  List<Object?> get props => [eventId, message];
}

/// نجح تحميل أعضاء فعالية
class EventMembersLoaded extends EventsState {
  final List<EventMember> members;
  final int total;
  final bool hasMore;

  const EventMembersLoaded({
    required this.members,
    required this.total,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [members, total, hasMore];
}

/// نجحت دعوة الأصدقاء
class FriendsInvited extends EventsState {
  final String message;

  const FriendsInvited(this.message);

  @override
  List<Object?> get props => [message];
}

/// نجح تحميل منشورات فعالية
class EventPostsLoaded extends EventsState {
  final List<dynamic> posts;
  final int total;
  final bool hasMore;

  const EventPostsLoaded({
    required this.posts,
    required this.total,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [posts, total, hasMore];
}

/// حدث خطأ
class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// نجح تحميل التصنيفات
class EventCategoriesLoaded extends EventsState {
  final List<EventCategory> categories;

  const EventCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// نجح تحديث صورة الفعالية
class EventPictureUpdated extends EventsState {
  final Event event;
  final String eventPicture;

  const EventPictureUpdated({
    required this.event,
    required this.eventPicture,
  });

  @override
  List<Object?> get props => [event, eventPicture];
}

/// نجح تحديث غلاف الفعالية
class EventCoverUpdated extends EventsState {
  final Event event;
  final String eventCover;

  const EventCoverUpdated({
    required this.event,
    required this.eventCover,
  });

  @override
  List<Object?> get props => [event, eventCover];
}
