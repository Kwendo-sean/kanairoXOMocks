import '../../core/utils/url_helper.dart';
import '../../utils/auth_storage.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String messageType;
  // text, photo, video, voice, suggestion, system
  final String content;
  final String? mediaUrl;
  final double? mediaDuration;
  final String? suggestionType;
  final Map<String, dynamic>? suggestionData;
  final bool isRead;
  final DateTime sentAt;
  final bool isDeleted;
  
  bool get isFromMe =>
    senderId == AuthStorage.getCachedUserId();
  
  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.messageType,
    required this.content,
    this.mediaUrl,
    this.mediaDuration,
    this.suggestionType,
    this.suggestionData,
    required this.isRead,
    required this.sentAt,
    required this.isDeleted,
  });
  
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name'] ?? '',
      senderPhotoUrl: UrlHelper.fixMediaUrl(json['sender_photo']),
      messageType: json['message_type'] ?? 'text',
      content: json['content'] ?? '',
      mediaUrl: UrlHelper.fixMediaUrl(json['media_url_full']),
      mediaDuration: (json['media_duration'] as num?)?.toDouble(),
      suggestionType: json['suggestion_type'],
      suggestionData: json['suggestion_data'] as Map<String, dynamic>?,
      isRead: json['is_read'] ?? false,
      sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}
