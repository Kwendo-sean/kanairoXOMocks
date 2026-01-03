class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;
  
  const Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.imageUrl,
    this.actionUrl,
  });
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }
  
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['userId'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.general,
      ),
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
    );
  }
}

enum NotificationType {
  connectionRequest,
  connectionAccepted,
  message,
  eventReminder,
  eventUpdate,
  paymentSuccess,
  ticketReady,
  newExperience,
  moodMatch,
  system,
  general,
}

class ConnectionRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserImage;
  final String? message;
  final DateTime sentAt;
  final bool isAccepted;
  final bool isDeclined;
  final DateTime? respondedAt;
  
  const ConnectionRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserImage,
    this.message,
    required this.sentAt,
    this.isAccepted = false,
    this.isDeclined = false,
    this.respondedAt,
  });
  
  bool get isPending => !isAccepted && !isDeclined;
}