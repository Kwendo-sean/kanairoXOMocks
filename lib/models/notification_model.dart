import 'package:flutter/foundation.dart';

@immutable
class NotificationModel {
  final String id;
  final String notificationType;
  final String message;
  final NotificationSender? sender;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.notificationType,
    required this.message,
    this.sender,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
    this.data = const {},
  });

  bool get isMomentNotification => [
        'moment_like',
        'moment_comment',
        'moment_save',
        'new_like',
        'new_comment'
      ].contains(notificationType);

  bool get isConnectionNotification => [
        'connection_request',
        'connection_accepted',
        'connection_rejected'
      ].contains(notificationType);

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      notificationType: json['notification_type'] ?? json['type'] ?? '',
      message: json['message'] ?? json['body'] ?? '',
      sender: json['sender'] != null ? NotificationSender.fromJson(json['sender']) : null,
      referenceId: json['reference_id']?.toString(),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : (json['results_data'] is Map ? Map<String, dynamic>.from(json['results_data']) : {}),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? notificationType,
    String? message,
    NotificationSender? sender,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      notificationType: notificationType ?? this.notificationType,
      message: message ?? this.message,
      sender: sender ?? this.sender,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}

class NotificationSender {
  final String id;
  final String name;
  final String? photo;
  final bool isOfficial;

  const NotificationSender({
    required this.id,
    required this.name,
    this.photo,
    this.isOfficial = false,
  });

  factory NotificationSender.fromJson(Map<String, dynamic> json) {
    return NotificationSender(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['username'] ?? 'User',
      photo: json['photo'] ?? json['profile_photo'] ?? json['avatar_url'],
      isOfficial: json['is_official'] ?? false,
    );
  }
}
