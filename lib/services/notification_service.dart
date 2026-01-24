// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Notification>> getNotifications({
    String? type,
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      if (unreadOnly) {
        queryParams['unread_only'] = 'true';
      }

      final response = await _apiClient.get(
        'notifications/',
        queryParameters: queryParams,
      );

      if (response is Map && response.containsKey('results')) {
        // Paginated response
        final results = response['results'] as List;
        return results.map((json) => Notification.fromJson(json)).toList();
      } else if (response is List) {
        // Direct list response
        return response.map((json) => Notification.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  // Get connection requests specifically
  Future<List<Notification>> getConnectionRequests() async {
    try {
      final response = await _apiClient.get('notifications/connection-requests/');

      if (response is List) {
        return response.map((json) => Notification.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching connection requests: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final response = await _apiClient.get('notifications/stats/');
      return response is Map ? Map<String, dynamic>.from(response) : {};
    } catch (e) {
      print('Error fetching notification stats: $e');
      return {};
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.post(
        'notifications/$notificationId/read/',
        {},
      );
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post('notifications/read-all/', {});
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiClient.delete('notifications/$notificationId/delete/');
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<Notification?> getNotification(String notificationId) async {
    try {
      final response = await _apiClient.get('notifications/$notificationId/');
      return Notification.fromJson(response);
    } catch (e) {
      print('Error fetching single notification: $e');
      return null;
    }
  }
}