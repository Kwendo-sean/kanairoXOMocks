import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/messaging/conversation_model.dart';
import '../safe_network_image.dart';

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final ConversationModel conversation;
  final VoidCallback? onBack;
  final VoidCallback? onMore;

  const ChatHeader({
    super.key,
    required this.conversation,
    this.onBack,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final borderColor = isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: SafeNetworkImage(
                url: conversation.otherParticipantPhoto,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conversation.otherParticipantName,
                  style: AppTypography.displayMedium.copyWith(fontSize: 16),
                ),
                Text(
                  'Active now',
                  style: AppTypography.caption.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black),
          onPressed: onMore,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: borderColor,
          height: 1,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  static String getMessagePreview(String type) {
    switch (type) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Voice message';
      case 'location':
        return 'Location';
      case 'event':
        return 'Event';
      case 'date_invite':
        return 'Date invitation';
      case 'payment':
        return 'Payment';
      default:
        return 'New message';
    }
  }
}
