import 'package:flutter/material.dart';
import 'package:kanairoxo/models/notification_model.dart';
import 'package:kanairoxo/services/notification_service.dart';
import 'package:kanairoxo/services/api_client.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final ApiClient _apiClient = ApiClient();

  List<NotificationModel> _all = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;

  // Getters
  List<NotificationModel> get all => _all;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ITEM 4: NOTIFICATIONS — tab filtering
  List<NotificationModel> get moments => _all.where((n) => [
        'moment_like',
        'moment_comment',
        'moment_save',
        'new_like',
        'new_comment'
      ].contains(n.notificationType)).toList();

  List<NotificationModel> get connections => _all.where((n) => [
        'connection_request',
        'connection_accepted',
        'connection_rejected'
      ].contains(n.notificationType)).toList();

  bool get hasUnreadMoments => moments.any((n) => !n.isRead);
  bool get hasUnreadConnections => connections.any((n) => !n.isRead);

  // For backward compatibility
  List<NotificationModel> get notifications => _all;
  List<NotificationModel> get momentNotifications => moments;
  List<NotificationModel> get connectionRequests => connections;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ITEM 3: Read unread_count from metadata
      final result = await _notificationService.getNotificationsWithMetadata();
      _all = result['notifications'] as List<NotificationModel>;
      _unreadCount = result['unread_count'] as int;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  Future<void> loadConnections() async => loadNotifications();
  Future<void> loadMoments() async => loadNotifications();

  Future<void> markAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      final index = _all.indexWhere((n) => n.id == id);
      if (index != -1 && !_all[index].isRead) {
        _all[index] = _all[index].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _all = _all.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<bool> acceptConnection(String connectionId, int notificationId) async {
    try {
      await _apiClient.post('api/v1/connections/$connectionId/accept/', {});
      _all.removeWhere((n) => n.id == notificationId);
      await loadNotifications(); // Refresh count
      return true;
    } catch (e) {
      debugPrint('Error accepting connection: $e');
      return false;
    }
  }

  Future<bool> declineConnection(String connectionId, int notificationId) async {
    try {
      await _apiClient.post('api/v1/connections/$connectionId/reject/', {});
      _all.removeWhere((n) => n.id == notificationId);
      await loadNotifications(); // Refresh count
      return true;
    } catch (e) {
      debugPrint('Error declining connection: $e');
      return false;
    }
  }
}
