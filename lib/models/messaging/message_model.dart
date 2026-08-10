import '../../core/utils/url_helper.dart';

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
  final bool isMine;
  // [{emoji, count, reacted_by_me}] — populated by backend once reactions are live
  final List<Map<String, dynamic>> reactions;

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
    required this.isMine,
    this.reactions = const [],
  });

  MessageModel copyWith({List<Map<String, dynamic>>? reactions, bool? isDeleted}) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      messageType: messageType,
      content: content,
      mediaUrl: mediaUrl,
      mediaDuration: mediaDuration,
      suggestionType: suggestionType,
      suggestionData: suggestionData,
      isRead: isRead,
      sentAt: sentAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isMine: isMine,
      reactions: reactions ?? this.reactions,
    );
  }

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
      // The API sends an offset-aware timestamp, which DateTime.parse turns
      // into a UTC DateTime. Rendering that without toLocal() showed every
      // message three hours behind Nairobi.
      sentAt: (DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now()).toLocal(),
      isDeleted: json['is_deleted'] ?? false,
      isMine: json['is_mine'] ?? false,
      reactions: (json['reactions'] as List?)
              ?.map((r) => r as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}
