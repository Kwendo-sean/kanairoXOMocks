import '../../core/utils/url_helper.dart';

class ConversationModel {
  final String id;
  final ConversationUser otherUser;
  final String status;
  final SparkStatus sparkStatus;
  final CanSend canSend;
  final int? messagesRemaining;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool meetupPlanned;
  
  ConversationModel({
    required this.id,
    required this.otherUser,
    required this.status,
    required this.sparkStatus,
    required this.canSend,
    this.messagesRemaining,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
    required this.meetupPlanned,
  });

  String get otherParticipantName => otherUser.name;
  String? get otherParticipantPhoto => otherUser.photoUrl;
  
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      otherUser: ConversationUser.fromJson(json['other_user'] ?? {}),
      status: json['status'] ?? 'active',
      sparkStatus: SparkStatus.fromJson(json['spark_status'] ?? {}),
      canSend: CanSend.fromJson(json['can_send'] ?? {}),
      messagesRemaining: json['messages_remaining'],
      lastMessagePreview: json['last_message_preview'],
      lastMessageAt: json['last_message_at'] != null
        ? DateTime.tryParse(json['last_message_at'])
        : null,
      unreadCount: json['unread_count_a'] ?? 0,
      meetupPlanned: json['meetup_planned'] ?? false,
    );
  }
}

class ConversationUser {
  final String id;
  final String name;
  final String? photoUrl;
  final String? neighborhood;
  
  ConversationUser({
    required this.id,
    required this.name,
    this.photoUrl,
    this.neighborhood,
  });
  
  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      photoUrl: UrlHelper.fixMediaUrl(json['photo_url']),
      neighborhood: json['neighborhood'],
    );
  }
}

class SparkStatus {
  final bool active;
  final int? secondsRemaining;
  final String label;
  
  SparkStatus({
    required this.active,
    this.secondsRemaining,
    required this.label,
  });
  
  factory SparkStatus.fromJson(Map<String, dynamic> json) {
    return SparkStatus(
      active: json['active'] ?? true,
      secondsRemaining: json['seconds_remaining'],
      label: json['label'] ?? '',
    );
  }
}

class CanSend {
  final bool allowed;
  final String? reason;
  
  CanSend({
    required this.allowed,
    this.reason,
  });
  
  factory CanSend.fromJson(Map<String, dynamic> json) {
    return CanSend(
      allowed: json['allowed'] ?? true,
      reason: json['reason'],
    );
  }
}
