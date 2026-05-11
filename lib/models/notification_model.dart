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
  momentLike,
  momentComment,
  profileView,
  systemAlert,
  communityUpdate,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    return switch (this) {
      NotificationType.momentLike => 'moment_like',
      NotificationType.momentComment => 'moment_comment',
      NotificationType.connectionRequest => 'connection_request',
      NotificationType.connectionAccepted => 'connection_accepted',
      NotificationType.connectionRejected => 'connection_rejected',
      NotificationType.newMessage => 'new_message',
      NotificationType.eventInvitation => 'event_invitation',
      NotificationType.eventReminder => 'event_reminder',
      NotificationType.ticketReady => 'ticket_ready',
      NotificationType.paymentSuccess => 'payment_success',
      NotificationType.paymentFailed => 'payment_failed',
      NotificationType.newComment => 'new_comment',
      NotificationType.newLike => 'new_like',
      NotificationType.profileView => 'profile_view',
      NotificationType.systemAlert => 'system_alert',
      NotificationType.communityUpdate => 'community_update',
    };
  }

  static NotificationType fromString(String value) {
    return switch (value) {
      'moment_like' => NotificationType.momentLike,
      'moment_comment' => NotificationType.momentComment,
      'connection_request' => NotificationType.connectionRequest,
      'connection_accepted' => NotificationType.connectionAccepted,
      'connection_rejected' => NotificationType.connectionRejected,
      'new_message' => NotificationType.newMessage,
      'event_invitation' => NotificationType.eventInvitation,
      'event_reminder' => NotificationType.eventReminder,
      'ticket_ready' => NotificationType.ticketReady,
      'payment_success' => NotificationType.paymentSuccess,
      'payment_failed' => NotificationType.paymentFailed,
      'new_comment' => NotificationType.newComment,
      'new_like' => NotificationType.newLike,
      'profile_view' => NotificationType.profileView,
      'system_alert' => NotificationType.systemAlert,
      'community_update' => NotificationType.communityUpdate,
      _ => NotificationType.systemAlert,
    };
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
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String timeAgo; // Added as per API requirement
  final bool isRead;
  final Map<String, dynamic>? sender;

  const Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.icon,
    this.imageUrl,
    this.data = const {},
    required this.timestamp,
    required this.timeAgo,
    this.isRead = false,
    this.sender,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      type: NotificationTypeExtension.fromString(json['type'] ?? ''),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      icon: json['icon'],
      imageUrl: json['image_url'],
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      timestamp: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      timeAgo: json['time_ago'] ?? '',
      isRead: json['is_read'] ?? false,
      sender: json['sender'] is Map ? Map<String, dynamic>.from(json['sender']) : null,
    );
  }

  Notification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? icon,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    String? timeAgo,
    bool? isRead,
    Map<String, dynamic>? sender,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      timeAgo: timeAgo ?? this.timeAgo,
      isRead: isRead ?? this.isRead,
      sender: sender ?? this.sender,
    );
  }
}
