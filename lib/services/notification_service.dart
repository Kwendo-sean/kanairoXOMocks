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
import 'package:kanairoxo/models/notification_model.dart' as model;

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
      final type = message.data['type'] ?? '';
      
      // Date Planning Routing
      if (message.data.containsKey('date_request_id')) {
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
        if (message.data.containsKey('date_request_id')) {
          _navigatorKey?.currentState?.push(
            MaterialPageRoute(builder: (_) => const DateRequestsScreen()));
        }
      }
    });
  }

  Future<List<model.Notification>> getNotifications({String? type}) async {
    try {
      final queryParams = type != null ? {'type': type} : null;
      final response = await _apiClient.get('api/v1/notifications/', queryParameters: queryParams);
      
      final List<dynamic> list;
      if (response is List) {
        list = response;
      } else if (response['results'] != null) {
        list = response['results'] as List;
      } else {
        list = response['notifications'] as List? ?? [];
      }
      
      return list.map((n) => model.Notification.fromJson(n)).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
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
