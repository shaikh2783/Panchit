import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/notifications/data/models/notification.dart';
import 'package:snginepro/features/notifications/domain/notifications_repository.dart';

class NotificationsNotifier extends ChangeNotifier {
  NotificationsNotifier(this._repository);

  final NotificationsRepository _repository;

  final List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _unreadCount = 0;
  int _total = 0;
  int _offset = 0;
  final int _limit = 20;

  // Getters
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  int get total => _total;
  bool get hasMore => _notifications.length < _total;

  /// Fetch notifications (initial or refresh)
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _notifications.clear();
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.getNotifications(
        offset: _offset,
        limit: _limit,
      );

      _notifications.addAll(response.data.notifications);
      _unreadCount = response.data.unreadCount;
      _total = response.data.total;
      _offset += response.data.notifications.length;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An error occurred while fetching notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more notifications (Pagination)
  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _repository.getNotifications(
        offset: _offset,
        limit: _limit,
      );

      _notifications.addAll(response.data.notifications);
      _unreadCount = response.data.unreadCount;
      _total = response.data.total;
      _offset += response.data.notifications.length;
    } on ApiException catch (e) {
    } catch (e) {
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(int notificationId) async {
    // Update UI immediately (Optimistic update)
    final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (index == -1 || _notifications[index].seen) return;

    final oldNotification = _notifications[index];
    _notifications[index] = oldNotification.copyWith(seen: true);
    _unreadCount = max(0, _unreadCount - 1);
    notifyListeners();

    try {
      await _repository.markNotificationRead(notificationId);
    } on ApiException catch (e) {
      // إرجاع الحالة القديمة في حالة الفشل
      _notifications[index] = oldNotification;
      _unreadCount = min(_total, _unreadCount + 1);
      notifyListeners();
    } catch (e) {
      _notifications[index] = oldNotification;
      _unreadCount = min(_total, _unreadCount + 1);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;

    // Save old state
    final oldNotifications = List<NotificationModel>.from(_notifications);
    final oldUnreadCount = _unreadCount;

    // Update UI immediately
    _notifications.clear();
    _notifications.addAll(
      oldNotifications.map((n) => n.copyWith(seen: true)),
    );
    _unreadCount = 0;
    notifyListeners();

    try {
      await _repository.markAllNotificationsRead();
    } on ApiException catch (e) {
      // إرجاع الحالة القديمة في حالة الفشل
      _notifications.clear();
      _notifications.addAll(oldNotifications);
      _unreadCount = oldUnreadCount;
      notifyListeners();
      rethrow;
    } catch (e) {
      _notifications.clear();
      _notifications.addAll(oldNotifications);
      _unreadCount = oldUnreadCount;
      notifyListeners();
      rethrow;
    }
  }

  /// Update total unread notifications count only (for use in the icon)
  Future<void> refreshUnreadCount() async {
    try {
      final response = await _repository.getNotifications(
        offset: 0,
        limit: 1,
      );
      _unreadCount = response.data.unreadCount;
      notifyListeners();
    } catch (e) {
    }
  }
}
