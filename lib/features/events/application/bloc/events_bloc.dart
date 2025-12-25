import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/event.dart';
import '../../data/models/event_member.dart';
import '../../data/services/events_service.dart';
import 'events_events.dart';
import 'events_states.dart';

/// Events Bloc
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsService _eventsService;

  // Pagination trackers
  int _suggestedOffset = 0;
  int _myEventsOffset = 0;
  int _membersOffset = 0;
  int _postsOffset = 0;
  int _currentPostsEventId = 0; // Track which event's posts we're loading
  static const int _limit = 20;
  
  // Store events for pagination
  List<Event> _suggestedEvents = [];
  List<Event> _myEvents = [];

  EventsBloc(this._eventsService) : super(EventsInitial()) {
    on<FetchSuggestedEventsEvent>(_onFetchSuggestedEvents);
    on<FetchMyEventsEvent>(_onFetchMyEvents);
    on<SearchEventsEvent>(_onSearchEvents);
    on<FetchEventDetailsEvent>(_onFetchEventDetails);
    on<CreateEventEvent>(_onCreateEvent);
    on<UpdateEventEvent>(_onUpdateEvent);
    on<DeleteEventEvent>(_onDeleteEvent);
    on<JoinEventEvent>(_onJoinEvent);
    on<LeaveEventEvent>(_onLeaveEvent);
    on<FetchEventMembersEvent>(_onFetchEventMembers);
    on<InviteFriendsToEventEvent>(_onInviteFriends);
    on<FetchEventPostsEvent>(_onFetchEventPosts);
    on<FetchEventCategoriesEvent>(_onFetchEventCategories);
    on<UpdateEventPictureEvent>(_onUpdateEventPicture);
    on<UpdateEventCoverEvent>(_onUpdateEventCover);
  }

  /// جلب فعاليات مقترحة
  Future<void> _onFetchSuggestedEvents(
    FetchSuggestedEventsEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      // إصدار Loading state دائماً للتابات
      if (event.refresh) {
        _suggestedOffset = 0;
        _suggestedEvents = [];
      }
      
      emit(EventsLoading());

      final result = await _eventsService.getSuggestedEvents(
        categoryId: event.categoryId,
        type: event.type,
        country: event.country,
        offset: _suggestedOffset,
        limit: _limit,
      );

      if (result['status'] == 'success') {
        final eventsList = result['events'] as List<Event>;
        final total = result['total'] as int;
        
        if (event.refresh) {
          // إذا كان refresh، نبدأ من جديد
          _suggestedEvents = eventsList;
          _suggestedOffset = eventsList.length;
        } else {
          // وإلا نضيف للقائمة الموجودة
          _suggestedEvents.addAll(eventsList);
          _suggestedOffset += eventsList.length;
        }
        
        final hasMore = _suggestedOffset < total;

        emit(SuggestedEventsLoaded(
          events: List.from(_suggestedEvents),
          total: total,
          hasMore: hasMore,
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to load suggested events'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// جلب فعالياتي
  Future<void> _onFetchMyEvents(
    FetchMyEventsEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      // إصدار Loading state دائماً للتابات
      if (event.refresh) {
        _myEventsOffset = 0;
        _myEvents = [];
      }
      
      emit(EventsLoading());

      final result = await _eventsService.getMyEvents(
        filter: event.filter,
        offset: _myEventsOffset,
        limit: _limit,
      );

      if (result['status'] == 'success') {
        final eventsList = result['events'] as List<Event>;
        final total = result['total'] as int;
        
        if (event.refresh) {
          // إذا كان refresh، نبدأ من جديد
          _myEvents = eventsList;
          _myEventsOffset = eventsList.length;
        } else {
          // وإلا نضيف للقائمة الموجودة
          _myEvents.addAll(eventsList);
          _myEventsOffset += eventsList.length;
        }
        
        final hasMore = _myEventsOffset < total;

        emit(MyEventsLoaded(
          events: List.from(_myEvents),
          total: total,
          hasMore: hasMore,
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to load my events'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// البحث عن فعاليات
  Future<void> _onSearchEvents(
    SearchEventsEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.searchEvents(
        query: event.query,
        limit: 50,
      );

      if (result['status'] == 'success') {
        emit(EventsSearchResultsLoaded(
          events: result['events'],
          query: event.query,
          total: result['total'],
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to search events'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// جلب تفاصيل فعالية
  Future<void> _onFetchEventDetails(
    FetchEventDetailsEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.getEvent(event.eventId);

      if (result['status'] == 'success') {
        emit(EventDetailsLoaded(result['event']));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to load event details'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// إنشاء فعالية
  Future<void> _onCreateEvent(
    CreateEventEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.createEvent(
        title: event.title,
        location: event.location,
        description: event.description,
        categoryId: event.categoryId,
        startDate: event.startDate,
        endDate: event.endDate,
        privacy: event.privacy,
        isOnline: event.isOnline,
        country: event.country,
        language: event.language,
        eventPicture: event.eventPicture,
        eventCover: event.eventCover,
      );

      if (result['status'] == 'success') {
        final eventId = int.parse(result['data']['event_id'].toString());
        emit(EventCreated(
          eventId: eventId,
          message: result['message'] ?? 'Event created successfully',
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to create event'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// تعديل فعالية
  Future<void> _onUpdateEvent(
    UpdateEventEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.updateEvent(
        eventId: event.eventId,
        title: event.title,
        description: event.description,
        location: event.location,
        categoryId: event.categoryId,
        startDate: event.startDate,
        endDate: event.endDate,
        privacy: event.privacy,
        isOnline: event.isOnline,
        country: event.country,
        language: event.language,
        eventPicture: event.eventPicture,
        eventCover: event.eventCover,
      );

      if (result['status'] == 'success') {
        emit(EventUpdated(result['message'] ?? 'Event updated successfully'));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to update event'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// حذف فعالية
  Future<void> _onDeleteEvent(
    DeleteEventEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.deleteEvent(event.eventId);

      if (result['status'] == 'success') {
        emit(EventDeleted(result['message'] ?? 'Event deleted successfully'));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to delete event'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// الانضمام لفعالية
  Future<void> _onJoinEvent(
    JoinEventEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.joinEvent(
        eventId: event.eventId,
        action: event.action,
      );

      if (result['status'] == 'success') {
        emit(EventJoined(
          eventId: event.eventId,
          status: event.action,
          message: result['message'] ?? 'Joined event successfully',
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to join event'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// مغادرة فعالية
  Future<void> _onLeaveEvent(
    LeaveEventEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.leaveEvent(event.eventId);

      if (result['status'] == 'success') {
        emit(EventLeft(
          eventId: event.eventId,
          message: result['message'] ?? 'Left event successfully',
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to leave event'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// جلب أعضاء فعالية
  Future<void> _onFetchEventMembers(
    FetchEventMembersEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      if (event.refresh) {
        _membersOffset = 0;
        emit(EventsLoading());
      }

      final result = await _eventsService.getEventMembers(
        eventId: event.eventId,
        type: event.type,
        offset: _membersOffset,
        limit: _limit,
      );

      if (result['status'] == 'success') {
        final membersList = result['members'] as List<EventMember>;
        final total = result['total'] as int;
        
        _membersOffset += membersList.length;
        final hasMore = _membersOffset < total;

        emit(EventMembersLoaded(
          members: membersList,
          total: total,
          hasMore: hasMore,
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to load members'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// دعوة أصدقاء
  Future<void> _onInviteFriends(
    InviteFriendsToEventEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.inviteFriends(
        eventId: event.eventId,
        userIds: event.userIds,
      );

      if (result['status'] == 'success') {
        emit(FriendsInvited(result['message'] ?? 'Friends invited successfully'));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to invite friends'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// جلب منشورات فعالية
  Future<void> _onFetchEventPosts(
    FetchEventPostsEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      // Reset offset if switching to a different event or refreshing
      if (_currentPostsEventId != event.eventId || event.refresh) {
        _postsOffset = 0;
        _currentPostsEventId = event.eventId;
        emit(EventsLoading());
      }

      final result = await _eventsService.getEventPosts(
        eventId: event.eventId,
        offset: _postsOffset,
        limit: _limit,
      );

      if (result['status'] == 'success') {
        final posts = result['data'] as List;
        final total = result['total'] as int? ?? posts.length;
        
        _postsOffset += posts.length;
        final hasMore = _postsOffset < total;

        emit(EventPostsLoaded(
          posts: posts,
          total: total,
          hasMore: hasMore,
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to load posts'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// جلب تصنيفات الفعاليات
  Future<void> _onFetchEventCategories(
    FetchEventCategoriesEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());
      
      final categories = await _eventsService.getEventCategories();
      
      emit(EventCategoriesLoaded(categories));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// تحديث صورة الفعالية
  Future<void> _onUpdateEventPicture(
    UpdateEventPictureEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.updateEventPicture(
        eventId: event.eventId,
        pictureData: event.pictureData,
      );

      if (result['status'] == 'success') {
        emit(EventPictureUpdated(
          event: result['event'],
          eventPicture: result['event_picture'],
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to update event picture'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  /// تحديث غلاف الفعالية
  Future<void> _onUpdateEventCover(
    UpdateEventCoverEvent event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(EventsLoading());

      final result = await _eventsService.updateEventCover(
        eventId: event.eventId,
        coverData: event.coverData,
      );


      if (result['status'] == 'success') {
        emit(EventCoverUpdated(
          event: result['event'],
          eventCover: result['event_cover'],
        ));
      } else {
        emit(EventsError(result['message'] ?? 'Failed to update event cover'));
      }
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }
}
