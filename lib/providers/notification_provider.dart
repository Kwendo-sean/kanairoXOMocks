import 'package:flutter/material.dart';
import 'package:kanairoxo/models/notification_model.dart' as model;
import 'package:kanairoxo/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<model.Notification> _notifications = [];
  List<model.Notification> _connectionRequests = [];
  List<model.Notification> _ticketNotifications = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<model.Notification> get notifications => _notifications;
  List<model.Notification> get connectionRequests => _connectionRequests;
  List<model.Notification> get ticketNotifications => _ticketNotifications;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  int get pendingConnectionRequests {
    return _connectionRequests.length;
  }

  // Load all notifications
  Future<void> loadNotifications() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load all notifications
      // _notifications = await _notificationService.getNotifications();

      // Show a notification for the newest unread notification
      if (unreadCount > 0) {
        final latestNotification = _notifications.firstWhere((n) => !n.isRead);
        await _notificationService.showNotification(
          latestNotification.title,
          latestNotification.body,
        );
      }

      // Load stats
      // _stats = await _notificationService.getNotificationStats();

      // Filter connection requests
      _connectionRequests = _notifications
          .where((n) =>
              n.type == model.NotificationType.connectionRequest && !n.isActionTaken)
          .toList();

      // Filter ticket notifications
      _ticketNotifications = _notifications
          .where((n) => n.type == model.NotificationType.ticketReady)
          .toList();
    } catch (e) {
      _error = e.toString();
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // await _notificationService.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);

        // Also update in filtered lists
        final connIndex = _connectionRequests.indexWhere((n) => n.id == notificationId);
        if (connIndex != -1) {
          _connectionRequests[connIndex] =
              _connectionRequests[connIndex].copyWith(isRead: true);
        }

        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      // await _notificationService.markAllAsRead();

      // Update all notifications locally
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _connectionRequests =
          _connectionRequests.map((n) => n.copyWith(isRead: true)).toList();

      // Update stats
      if (_stats.containsKey('unread')) {
        _stats['unread'] = 0;
      }

      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // await _notificationService.deleteNotification(notificationId);

      // Remove from local lists
      _notifications.removeWhere((n) => n.id == notificationId);
      _connectionRequests.removeWhere((n) => n.id == notificationId);
      _ticketNotifications.removeWhere((n) => n.id == notificationId);

      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Accept connection request
  Future<void> acceptConnectionRequest(String notificationId) async {
    try {
      // Find the notification
      final notification =
          _notifications.firstWhere((n) => n.id == notificationId);

      // Here you would call your connection API to accept the request
      // await _connectionService.acceptConnection(notification.data['connection_id']);

      // Update notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isActionTaken: true,
          isRead: true,
        );
      }

      // Remove from connection requests
      _connectionRequests.removeWhere((n) => n.id == notificationId);

      notifyListeners();
    } catch (e) {
      print('Error accepting connection request: $e');
      rethrow;
    }
  }

  // Decline connection request
  Future<void> declineConnectionRequest(String notificationId) async {
    try {
      // Find the notification
      final notification =
          _notifications.firstWhere((n) => n.id == notificationId);

      // Here you would call your connection API to decline the request
      // await _connectionService.declineConnection(notification.data['connection_id']);

      // Update notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isActionTaken: true,
          isRead: true,
        );
      }

      // Remove from connection requests
      _connectionRequests.removeWhere((n) => n.id == notificationId);

      notifyListeners();
    } catch (e) {
      print('Error declining connection request: $e');
      rethrow;
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
