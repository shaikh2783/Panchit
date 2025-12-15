import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/core/bloc/base_bloc.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/notifications/data/models/notification.dart';
import 'package:snginepro/features/notifications/domain/notifications_repository.dart';
// Events
abstract class NotificationsEvent extends BaseEvent {}
class LoadNotificationsEvent extends NotificationsEvent {}
class LoadMoreNotificationsEvent extends NotificationsEvent {}
class RefreshNotificationsEvent extends NotificationsEvent {}
class MarkNotificationAsReadEvent extends NotificationsEvent {
  final String notificationId;
  MarkNotificationAsReadEvent(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}
class MarkAllNotificationsAsReadEvent extends NotificationsEvent {}
class ClearAllNotificationsEvent extends NotificationsEvent {}
class DeleteNotificationEvent extends NotificationsEvent {
  final String notificationId;
  DeleteNotificationEvent(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}
class UpdateNotificationSettingsEvent extends NotificationsEvent {
  final Map<String, bool> settings;
  UpdateNotificationSettingsEvent(this.settings);
  @override
  List<Object?> get props => [settings];
}
// States
abstract class NotificationsState extends BaseState {
  const NotificationsState({
    super.isLoading,
    super.errorMessage,
    this.notifications = const [],
    this.unreadCount = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.currentOffset = 0,
  });
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentOffset;
  @override
  List<Object?> get props => [
        ...super.props,
        notifications,
        unreadCount,
        hasMore,
        isLoadingMore,
        currentOffset,
      ];
}
class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}
class NotificationsLoading extends NotificationsState {
  const NotificationsLoading({
    super.notifications,
    super.unreadCount,
    super.hasMore,
    super.currentOffset,
  }) : super(isLoading: true);
}
class NotificationsLoadingMore extends NotificationsState {
  const NotificationsLoadingMore({
    required super.notifications,
    required super.unreadCount,
    required super.hasMore,
    required super.currentOffset,
  }) : super(isLoadingMore: true);
}
class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({
    required super.notifications,
    required super.unreadCount,
    required super.hasMore,
    required super.currentOffset,
  });
}
class NotificationsError extends NotificationsState {
  const NotificationsError(
    String message, {
    super.notifications,
    super.unreadCount,
    super.hasMore,
    super.currentOffset,
  }) : super(errorMessage: message);
}
class NotificationMarkedAsRead extends NotificationsState {
  final String notificationId;
  const NotificationMarkedAsRead({
    required this.notificationId,
    required super.notifications,
    required super.unreadCount,
    required super.hasMore,
    required super.currentOffset,
  });
  @override
  List<Object?> get props => [...super.props, notificationId];
}
class AllNotificationsMarkedAsRead extends NotificationsState {
  const AllNotificationsMarkedAsRead({
    required super.notifications,
    required super.hasMore,
    required super.currentOffset,
  }) : super(unreadCount: 0);
}
class NotificationDeleted extends NotificationsState {
  final String notificationId;
  const NotificationDeleted({
    required this.notificationId,
    required super.notifications,
    required super.unreadCount,
    required super.hasMore,
    required super.currentOffset,
  });
  @override
  List<Object?> get props => [...super.props, notificationId];
}
class NotificationsCleared extends NotificationsState {
  const NotificationsCleared() : super(unreadCount: 0);
}
// Bloc
class NotificationsBloc extends BaseBloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc(this._repository) : super(const NotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<LoadMoreNotificationsEvent>(_onLoadMoreNotifications);
    on<RefreshNotificationsEvent>(_onRefreshNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
    on<ClearAllNotificationsEvent>(_onClearAllNotifications);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<UpdateNotificationSettingsEvent>(_onUpdateNotificationSettings);
  }
  final NotificationsRepository _repository;
  static const int _limit = 20;
  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      hasMore: state.hasMore,
      currentOffset: state.currentOffset,
    ));
    try {
      final response = await _repository.getNotifications(
        offset: 0,
        limit: _limit,
      );
      emit(NotificationsLoaded(
        notifications: response.data.notifications,
        unreadCount: response.data.unreadCount,
        hasMore: response.data.notifications.length >= _limit,
        currentOffset: response.data.notifications.length,
      ));
    } on ApiException catch (e) {
      emit(NotificationsError(
        e.message,
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
      ));
    } catch (e) {
      emit(NotificationsError(
        e.toString(),
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
      ));
    }
  }
  Future<void> _onLoadMoreNotifications(
    LoadMoreNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;
    emit(NotificationsLoadingMore(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      hasMore: state.hasMore,
      currentOffset: state.currentOffset,
    ));
    try {
      final response = await _repository.getNotifications(
        offset: state.currentOffset,
        limit: _limit,
      );
      emit(NotificationsLoaded(
        notifications: [...state.notifications, ...response.data.notifications],
        unreadCount: response.data.unreadCount,
        hasMore: response.data.notifications.length >= _limit,
        currentOffset: state.currentOffset + response.data.notifications.length,
      ));
    } on ApiException catch (e) {
      emit(NotificationsError(
        e.message,
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
      ));
    }
  }
  Future<void> _onRefreshNotifications(
    RefreshNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final response = await _repository.getNotifications(
        offset: 0,
        limit: _limit,
      );
      emit(NotificationsLoaded(
        notifications: response.data.notifications,
        unreadCount: response.data.unreadCount,
        hasMore: response.data.notifications.length >= _limit,
        currentOffset: response.data.notifications.length,
      ));
    } on ApiException catch (e) {
      emit(NotificationsError(
        e.message,
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
      ));
    }
  }
  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.markNotificationRead(int.parse(event.notificationId));
      // Update the notification in the list
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.notificationId.toString() == event.notificationId) {
          return notification.copyWith(seen: true);
        }
        return notification;
      }).toList();
      // Calculate new unread count
      final newUnreadCount = updatedNotifications
          .where((notification) => !notification.seen)
          .length;
      emit(NotificationMarkedAsRead(
        notificationId: event.notificationId,
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
      ));
    } on ApiException catch (e) {
      emit(NotificationsError(
        e.message,
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
      ));
    }
  }
  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.markAllNotificationsRead();
      // Mark all notifications as read
      final updatedNotifications = state.notifications
          .map((notification) => notification.copyWith(seen: true))
          .toList();
      emit(AllNotificationsMarkedAsRead(
        notifications: updatedNotifications,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
      ));
    } on ApiException catch (e) {
      emit(NotificationsError(
        e.message,
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
      ));
    }
  }
  Future<void> _onClearAllNotifications(
    ClearAllNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // Simple local clear since API doesn't support it
    emit(const NotificationsLoaded(
      notifications: [],
      unreadCount: 0,
      hasMore: false,
      currentOffset: 0,
    ));
  }
  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // Simple local deletion since API doesn't support it
    final updatedNotifications = state.notifications
        .where((notification) => notification.notificationId.toString() != event.notificationId)
        .toList();
    // Calculate new unread count
    final newUnreadCount = updatedNotifications
        .where((notification) => !notification.seen)
        .length;
    emit(NotificationDeleted(
      notificationId: event.notificationId,
      notifications: updatedNotifications,
      unreadCount: newUnreadCount,
      hasMore: state.hasMore,
      currentOffset: state.currentOffset - 1,
    ));
  }
  Future<void> _onUpdateNotificationSettings(
    UpdateNotificationSettingsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // Simple local settings update since API doesn't support it
    emit(NotificationsLoaded(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
      hasMore: state.hasMore,
      currentOffset: state.currentOffset,
    ));
  }
}