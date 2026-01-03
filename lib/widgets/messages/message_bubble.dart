import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import '../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final String userImage;
  
  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.userImage,
  });
  
  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.audio:
        return _buildAudioMessage();
      case MessageType.location:
        return _buildLocationMessage();
      case MessageType.event:
        return _buildEventMessage();
      case MessageType.dateInvitation:
        return _buildDateInvitationMessage();
      case MessageType.payment:
        return _buildPaymentMessage();
      default:
        return _buildTextMessage();
    }
  }
  
  Widget _buildTextMessage() {
    return Text(
      message.content,
      style: TextStyle(
        color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
        fontSize: 15,
      ),
    );
  }
  
  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppConstants.lightGray,
          ),
          child: message.attachmentUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.attachmentUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Icon(
                    PhosphorIcons.image(),
                    size: 40,
                    color: AppConstants.secondaryGray,
                  ),
                ),
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.content,
            style: TextStyle(
              color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildVideoMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: Stack(
            children: [
              message.attachmentUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.attachmentUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Icon(
                        PhosphorIcons.video(),
                        size: 40,
                        color: Colors.white70,
                      ),
                    ),
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.play(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.content,
            style: TextStyle(
              color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildAudioMessage() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Colors.white.withOpacity(0.2) 
            : AppConstants.primaryBeige,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.playCircle(),
            color: isCurrentUser ? Colors.white : AppConstants.primaryRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice message',
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '0:45',
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white70 : AppConstants.secondaryGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIcons.waveform(),
            color: isCurrentUser ? Colors.white70 : AppConstants.secondaryGray,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationMessage() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Colors.white.withOpacity(0.2) 
            : AppConstants.primaryBeige,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.mapPin(),
            color: isCurrentUser ? Colors.white : AppConstants.primaryRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Shared',
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bluestone Lane, SoHo',
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white70 : AppConstants.secondaryGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEventMessage() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Colors.white.withOpacity(0.2) 
            : AppConstants.primaryBeige,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? Colors.white30 : AppConstants.lightGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.calendar(),
                size: 16,
                color: isCurrentUser ? Colors.white : AppConstants.primaryRed,
              ),
              const SizedBox(width: 8),
              Text(
                'Event',
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Morning Coffee & Conversation',
            style: TextStyle(
              color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sat, Jan 4 • 9:00 AM',
            style: TextStyle(
              color: isCurrentUser ? Colors.white70 : AppConstants.secondaryGray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.white.withOpacity(0.3) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'View Details',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : AppConstants.primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateInvitationMessage() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(isCurrentUser ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.pink.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.heart(),
                size: 16,
                color: Colors.pink,
              ),
              const SizedBox(width: 8),
              Text(
                'Date Invitation',
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dinner at The Social Table',
            style: TextStyle(
              color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saturday, 8:00 PM • 15% discount',
            style: TextStyle(
              color: isCurrentUser ? Colors.white70 : AppConstants.secondaryGray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Accept',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.pink),
                  ),
                  child: Center(
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        color: Colors.pink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMessage() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Colors.white.withOpacity(0.2) 
            : AppConstants.primaryBeige,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? Colors.white30 : AppConstants.lightGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.creditCard(),
                size: 16,
                color: isCurrentUser ? Colors.white : AppConstants.primaryRed,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment',
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'KES 1,500.00',
            style: TextStyle(
              color: isCurrentUser ? Colors.white : AppConstants.primaryBlack,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Event ticket payment',
            style: TextStyle(
              color: isCurrentUser ? Colors.white70 : AppConstants.secondaryGray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.white.withOpacity(0.3) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'View Receipt',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : AppConstants.primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageStatus() {
    if (!isCurrentUser) return const SizedBox.shrink();
    
    if (message.isRead) {
      return Row(
        children: [
          Text(
            'Read',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            PhosphorIcons.checkCircle(),
            size: 12,
            color: Colors.blue.withOpacity(0.7),
          ),
        ],
      );
    } else if (message.isDelivered) {
      return Icon(
        PhosphorIcons.checkCircle(),
        size: 12,
        color: Colors.white.withOpacity(0.7),
      );
    } else {
      return Icon(
        PhosphorIcons.check(),
        size: 12,
        color: Colors.white.withOpacity(0.7),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(userImage),
            ),
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? AppConstants.primaryRed.withOpacity(0.9)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentUser 
                              ? Colors.white.withOpacity(0.7)
                              : AppConstants.secondaryGray,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCurrentUser) _buildMessageStatus(),
                      if (message.isExpired)
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            Icon(
                              PhosphorIcons.clock(),
                              size: 10,
                              color: isCurrentUser 
                                  ? Colors.white.withOpacity(0.7)
                                  : AppConstants.secondaryGray,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Expires',
                              style: TextStyle(
                                fontSize: 10,
                                color: isCurrentUser 
                                    ? Colors.white.withOpacity(0.7)
                                    : AppConstants.secondaryGray,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}