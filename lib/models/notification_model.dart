import 'package:flutter/foundation.dart';

enum NotificationType {
  connectionRequest,
  connectionAccepted,
  connectionRejected,
  newMessage,
  eventInvitation,
  eventReminder,
  ticketReady,
  paymentSuccess,
  paymentFailed,
  newComment,
  newLike,
  profileView,
  systemAlert,
  communityUpdate,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    return toString().split('.').last;
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.systemAlert,
    );
  }
}

@immutable
class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? icon;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionText;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final bool isSeen;
  final bool isActionTaken;
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? event;

  const Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.icon,
    this.imageUrl,
    this.actionUrl,
    this.actionText,
    this.data = const {},
    required this.timestamp,
    this.isRead = false,
    this.isSeen = false,
    this.isActionTaken = false,
    this.sender,
    this.event,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? '',
      userId: json['user']?.toString() ?? '',
      type: NotificationTypeExtension.fromString(json['type'] ?? ''),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      icon: json['icon'],
      imageUrl: json['image_url'],
      actionUrl: json['action_url'],
      actionText: json['action_text'],
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      timestamp: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      isSeen: json['is_seen'] ?? false,
      isActionTaken: json['is_action_taken'] ?? false,
      sender: json['sender'] is Map ? Map<String, dynamic>.from(json['sender']) : null,
      event: json['event'] is Map ? Map<String, dynamic>.from(json['event']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'icon': icon,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'action_text': actionText,
      'data': data,
      'created_at': timestamp.toIso8601String(),
      'is_read': isRead,
      'is_seen': isSeen,
      'is_action_taken': isActionTaken,
    };
  }

  Notification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? icon,
    String? imageUrl,
    String? actionUrl,
    String? actionText,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    bool? isSeen,
    bool? isActionTaken,
    Map<String, dynamic>? sender,
    Map<String, dynamic>? event,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isSeen: isSeen ?? this.isSeen,
      isActionTaken: isActionTaken ?? this.isActionTaken,
      sender: sender ?? this.sender,
      event: event ?? this.event,
    );
  }
}
