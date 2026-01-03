import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/models/notification_model.dart' as my_models;

class NotificationCard extends StatelessWidget {
  final my_models.Notification notification;
  final VoidCallback onTap;
  
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });
  
  IconData _getNotificationIcon(my_models.NotificationType type) {
    switch (type) {
      case my_models.NotificationType.connectionRequest:
        return PhosphorIcons.userPlus();
      case my_models.NotificationType.connectionAccepted:
        return PhosphorIcons.checkCircle();
      case my_models.NotificationType.message:
        return PhosphorIcons.chatCircle();
      case my_models.NotificationType.eventReminder:
        return PhosphorIcons.calendar();
      case my_models.NotificationType.eventUpdate:
        return PhosphorIcons.megaphone();
      case my_models.NotificationType.paymentSuccess:
        return PhosphorIcons.creditCard();
      case my_models.NotificationType.ticketReady:
        return PhosphorIcons.ticket();
      case my_models.NotificationType.newExperience:
        return PhosphorIcons.sparkle();
      case my_models.NotificationType.moodMatch:
        return PhosphorIcons.heart();
      default:
        return PhosphorIcons.bell();
    }
  }
  
  Color _getNotificationColor(my_models.NotificationType type) {
    switch (type) {
      case my_models.NotificationType.connectionRequest:
        return AppConstants.primaryRed;
      case my_models.NotificationType.connectionAccepted:
        return AppConstants.successGreen;
      case my_models.NotificationType.paymentSuccess:
        return AppConstants.successGreen;
      case my_models.NotificationType.ticketReady:
        return Colors.blue;
      default:
        return AppConstants.secondaryGray;
    }
  }
  
  @override
  Widget build(BuildContext context) {
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
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: notification.imageUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(notification.imageUrl!),
                      )
                    : Icon(
                        _getNotificationIcon(notification.type),
                        color: _getNotificationColor(notification.type),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: notification.isRead 
                          ? FontWeight.normal 
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConstants.secondaryGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.timeAgo,
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
                width: 8,
                height: 8,
                decoration: BoxDecoration(
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