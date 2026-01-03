class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime? expiresAt;
  final bool isDeleted;
  final Map<String, dynamic>? metadata;
  
  
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.receiverId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    this.isDelivered = false,
    this.deliveredAt,
    this.attachmentUrl,
    this.attachmentType,
    this.expiresAt,
    this.isDeleted = false,
    this.metadata,
  });
  
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  bool get isOutgoing => senderId == 'current_user_id'; // Replace with actual user id
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isDelivered': isDelivered,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'expiresAt': expiresAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'metadata': metadata,
    };
  }
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isDelivered: json['isDelivered'] ?? false,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      attachmentUrl: json['attachmentUrl'],
      attachmentType: json['attachmentType'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
      metadata: json['metadata'],
    );
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  location,
  event,
  dateInvitation,
  payment,
}

class Chat {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool hasUnseenStory;
  final MessageType lastMessageType;
  final bool isPinned;
  final bool isMuted;
  final DateTime? typingUntil;
  
  const Chat({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.hasUnseenStory = false,
    this.lastMessageType = MessageType.text,
    this.isPinned = false,
    this.isMuted = false,
    this.typingUntil,
  });
  
  String get lastMessageTimeFormatted {
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);
    
    if (difference.inDays > 7) {
      return '${lastMessageTime.day}/${lastMessageTime.month}/${lastMessageTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}