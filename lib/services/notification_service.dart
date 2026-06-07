import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/screens/notification_screen.dart';
import 'package:kanairoxo/screens/moments_screen.dart';
import 'package:kanairoxo/screens/messaging/conversations_screen.dart';
import 'package:kanairoxo/screens/messages/date_requests_screen.dart';
import 'package:kanairoxo/models/notification_model.dart';
import 'package:kanairoxo/models/ticket_model.dart';
import 'package:kanairoxo/features/tickets/screens/ticket_reveal_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _apiClient = ApiClient();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static final newMessageNotifier = ValueNotifier<String?>(null);

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          // Handle notification tap logic
        }
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationRouting(message.data);
    });

    // Request permission (required on Android 13+ and iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final type = message.data['type'] ?? '';

      // Update conversation notifier for in-app handling
      if (type == 'new_message') {
        newMessageNotifier.value = message.data['conversation_id'];
        newMessageNotifier.value = null;
      }

      // Show visible banner for every notification while app is open
      final title = message.notification?.title ?? message.data['title'] ?? 'KanairoXO';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      if (title.isNotEmpty || body.isNotEmpty) {
        showNotification(title, body);
      }
    });

    // Check for initial message (when app is opened from a terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationRouting(message.data);
      }
    });
  }

  Future<void> _handleNotificationRouting(Map<String, dynamic> data) async {
    final type = data['type'] ?? '';

    // Ticket Confirmed Routing
    if (data.containsKey('ticket_id') && type == 'ticket_confirmed') {
      final qrHash = data['qr_hash'] ?? data['ticket_id'];
      try {
        final response = await _apiClient.get('api/v1/tickets/$qrHash/');
        final ticket = TicketModel.fromJson(response);
        _navigatorKey?.currentState?.push(
          MaterialPageRoute(builder: (_) => TicketRevealScreen(ticket: ticket)));
      } catch (e) {
        debugPrint('Error fetching ticket for notification: $e');
      }
      return;
    }

    // Date Planning Routing
    if (data.containsKey('date_request_id')) {
      _navigatorKey?.currentState?.push(
        MaterialPageRoute(builder: (_) => const DateRequestsScreen()));
      return;
    }

    switch (type) {
      case 'new_message':
        _navigatorKey?.currentState?.push(
          MaterialPageRoute(builder: (_) => const ConversationsScreen()));
        break;
      case 'connection_request':
      case 'connection_accepted':
      case 'moment_like':
      case 'moment_comment':
      case 'moment_save':
        _navigatorKey?.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()));
        break;
      case 'drop_reminder':
        _navigatorKey?.currentState?.push(
          MaterialPageRoute(builder: (_) => const MomentsScreen()));
        break;
    }
  }

  // Updated to handle metadata like unread_count
  Future<Map<String, dynamic>> getNotificationsWithMetadata({String? type}) async {
    try {
      final queryParams = type != null ? {'type': type} : null;
      final response = await _apiClient.get('api/v1/notifications/', queryParameters: queryParams);
      
      final List<dynamic> list;
      int unreadCount = 0;

      if (response is Map) {
        unreadCount = response['unread_count'] ?? 0;
        if (response['results'] != null) {
          list = response['results'] as List;
        } else if (response['notifications'] != null) {
          list = response['notifications'] as List;
        } else {
          list = [];
        }
      } else if (response is List) {
        list = response;
      } else {
        list = [];
      }
      
      return {
        'notifications': list.map((n) => NotificationModel.fromJson(n)).toList(),
        'unread_count': unreadCount,
      };
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return {
        'notifications': <NotificationModel>[],
        'unread_count': 0,
      };
    }
  }

  Future<List<NotificationModel>> getNotifications({String? type}) async {
    final result = await getNotificationsWithMetadata(type: type);
    return result['notifications'] as List<NotificationModel>;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.post('api/v1/notifications/$notificationId/read/', {});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post('api/v1/notifications/mark-all-read/', {});
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('api/v1/notifications/unread-count/');
      return response['unread_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> registerFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _apiClient.post('api/v1/auth/device/register/', {
          'fcm_token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
      }
    } catch (e) {
      debugPrint('FCM Token reg error: $e');
    }
  }

  Future<void> registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _sendTokenToBackend(token);
      FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToBackend);
    } catch (e) {
      debugPrint('Token reg error: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      // Use a stable device ID based on the token itself
      final deviceId = 'device_${token.hashCode.abs()}';
      await ApiClient.instance.dio.post(
        'api/v1/auth/device/register/',
        data: {
          'device_id': deviceId,
          'fcm_token': token,
          'device_type': Platform.isIOS ? 'ios' : 'android',
        },
      );
      debugPrint('FCM token registered: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('Token send error: $e');
    }
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'kanairo_notifications',
      'KanairoXO Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
