import 'package:flutter/material.dart';
import 'package:kanairoxo/models/notification_model.dart' as model;
import 'package:kanairoxo/services/notification_service.dart';
import 'package:kanairoxo/services/api_client.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final ApiClient _apiClient = ApiClient();

  List<model.Notification> _notifications = [];
  List<model.Notification> _connectionRequests = [];
  List<model.Notification> _momentNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<model.Notification> get notifications => _notifications;
  List<model.Notification> get connectionRequests => _connectionRequests;
  List<model.Notification> get momentNotifications => _momentNotifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingConnectionRequests => _connectionRequests
      .where((n) => n.type == model.NotificationType.connectionRequest)
      .length;

  Future<void> loadNotifications() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _unreadCount = await _notificationService.getUnreadCount();
      _notifications = await _notificationService.getNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConnections() async {
    try {
      _connectionRequests = await _notificationService.getNotifications(type: 'connections');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading connections: $e');
    }
  }

  Future<void> loadMoments() async {
    try {
      _momentNotifications = await _notificationService.getNotifications(type: 'moments');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading moments: $e');
    }
  }

  Future<bool> acceptConnection(String connectionId, String notificationId) async {
    try {
      await _apiClient.post('api/v1/connections/$connectionId/accept/', {});
    } catch (e) {
      final msg = e.toString();
      // 404 = already processed — still dismiss the card
      if (!msg.contains('404')) {
        debugPrint('Error accepting connection: $e');
        return false;
      }
    }
    _removeFromAllLists(notificationId);
    notifyListeners();
    return true;
  }

  Future<bool> declineConnection(String connectionId, String notificationId) async {
    try {
      await _apiClient.post('api/v1/connections/$connectionId/reject/', {});
    } catch (e) {
      final msg = e.toString();
      // 404 = already processed — still dismiss the card
      if (!msg.contains('404')) {
        debugPrint('Error declining connection: $e');
        return false;
      }
    }
    _removeFromAllLists(notificationId);
    notifyListeners();
    return true;
  }

  void _removeFromAllLists(String notificationId) {
    _connectionRequests.removeWhere((n) => n.id == notificationId);
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications();
    await loadConnections();
    await loadMoments();
  }
}
