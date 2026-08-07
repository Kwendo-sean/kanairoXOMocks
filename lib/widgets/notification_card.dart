import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'connection_request': return PhosphorIcons.userPlus();
      case 'connection_accepted': return PhosphorIcons.checkCircle();
      case 'new_message': return PhosphorIcons.chatCircle();
      case 'event_reminder': return PhosphorIcons.calendar();
      case 'community_update': return PhosphorIcons.megaphone();
      case 'payment_success': return PhosphorIcons.creditCard();
      case 'ticket_ready': return PhosphorIcons.ticket();
      case 'new_like':
      case 'moment_like': return PhosphorIcons.heart();
      default: return PhosphorIcons.bell();
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'connection_request': return AppConstants.primaryRed;
      case 'connection_accepted':
      case 'payment_success': return AppConstants.successGreen;
      case 'ticket_ready': return Colors.blue;
      default: return AppConstants.secondaryGray;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = notification.notificationType;
    final senderPhoto = notification.sender?.photo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(
            color: notification.isRead
                ? AppConstants.lightGray
                : AppConstants.primaryRed.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _getNotificationColor(type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: senderPhoto != null
                    ? CircleAvatar(backgroundImage: NetworkImage(senderPhoto))
                    : Icon(_getNotificationIcon(type),
                        color: _getNotificationColor(type)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.sender?.name ?? 'KanairoXO',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConstants.secondaryGray,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: AppConstants.secondaryGray,
                        ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppConstants.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
