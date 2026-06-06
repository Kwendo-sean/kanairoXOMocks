import 'package:flutter/foundation.dart';

@immutable
class NotificationModel {
  final int id;
  final String notificationType;
  final String message;
  final NotificationSender? sender;
  final int? referenceId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data; // Added to handle extra fields like connection_id

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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      notificationType: json['notification_type'] ?? json['type'] ?? '',
      message: json['message'] ?? json['body'] ?? '',
      sender: json['sender'] != null ? NotificationSender.fromJson(json['sender']) : null,
      referenceId: json['reference_id'] is int ? json['reference_id'] : int.tryParse(json['reference_id']?.toString() ?? ''),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : (json['results_data'] is Map ? Map<String, dynamic>.from(json['results_data']) : {}),
    );
  }

  NotificationModel copyWith({
    int? id,
    String? notificationType,
    String? message,
    NotificationSender? sender,
    int? referenceId,
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
  final int id;
  final String name;
  final String? photo;
  final bool isOfficial; // Added as per item 5

  const NotificationSender({
    required this.id,
    required this.name,
    this.photo,
    this.isOfficial = false,
  });

  factory NotificationSender.fromJson(Map<String, dynamic> json) {
    return NotificationSender(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? json['username'] ?? 'User',
      photo: json['photo'] ?? json['profile_photo'] ?? json['avatar_url'],
      isOfficial: json['is_official'] ?? false,
    );
  }
}
