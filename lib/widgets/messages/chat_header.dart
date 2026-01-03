import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/models/message_model.dart';

class ChatHeader extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  
  const ChatHeader({
    super.key,
    required this.chat,
    required this.onTap,
  });
  
  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.image:
        return PhosphorIcons.image();
      case MessageType.video:
        return PhosphorIcons.video();
      case MessageType.audio:
        return PhosphorIcons.microphone();
      case MessageType.location:
        return PhosphorIcons.mapPin();
      case MessageType.event:
        return PhosphorIcons.calendar();
      case MessageType.dateInvitation:
        return PhosphorIcons.heart();
      case MessageType.payment:
        return PhosphorIcons.creditCard();
      default:
        return PhosphorIcons.chatCircle();
    }
  }
  
  String _getMessagePreview() {
    if (chat.lastMessageType != MessageType.text) {
      switch (chat.lastMessageType) {
        case MessageType.image:
          return '📷 Photo';
        case MessageType.video:
          return '🎬 Video';
        case MessageType.audio:
          return '🎤 Voice message';
        case MessageType.location:
          return '📍 Location';
        case MessageType.event:
          return '📅 Event';
        case MessageType.dateInvitation:
          return '💕 Date invitation';
        case MessageType.payment:
          return '💳 Payment';
        default:
          return chat.lastMessage;
      }
    }
    return chat.lastMessage;
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppConstants.lightGray.withOpacity(0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            // User avatar with online status
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(chat.userImage),
                ),
                if (chat.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppConstants.successGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                if (chat.hasUnseenStory)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.userName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: chat.unreadCount > 0 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isPinned)
                         Icon(
                          PhosphorIcons.pushPin(),
                          size: 14,
                          color: AppConstants.secondaryGray,
                        ),
                      if (chat.isMuted)
                        const SizedBox(width: 8),
                      if (chat.isMuted)
                         Icon(
                          PhosphorIcons.speakerSlash(),
                          size: 14,
                          color: AppConstants.secondaryGray,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Last message preview
                  Row(
                    children: [
                      if (chat.lastMessageType != MessageType.text)
                        Icon(
                          _getMessageTypeIcon(chat.lastMessageType),
                          size: 14,
                          color: AppConstants.secondaryGray,
                        ),
                      if (chat.lastMessageType != MessageType.text)
                        const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getMessagePreview(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: chat.unreadCount > 0 
                                ? AppConstants.primaryBlack 
                                : AppConstants.secondaryGray,
                            fontWeight: chat.unreadCount > 0 
                                ? FontWeight.w500 
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.typingUntil != null && 
                          chat.typingUntil!.isAfter(DateTime.now()))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Typing',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppConstants.primaryRed,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConstants.primaryRed,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Time and unread badge
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.clock(),
                        size: 12,
                        color: AppConstants.secondaryGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chat.lastMessageTimeFormatted,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: AppConstants.secondaryGray,
                        ),
                      ),
                      const Spacer(),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat.unreadCount > 99 
                                ? '99+' 
                                : chat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}