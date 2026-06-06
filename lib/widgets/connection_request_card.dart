import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/messaging/conversation_model.dart';
import '../services/api_client.dart';
import '../screens/messaging/chat_screen.dart';
import '../core/theme/app_colors.dart';

class ConnectionRequestCard extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isProcessing;
  final bool? isAccepted;
  final bool? isDeclined;

  const ConnectionRequestCard({
    super.key,
    required this.notification,
    required this.onAccept,
    required this.onDecline,
    this.isProcessing = false,
    this.isAccepted,
    this.isDeclined,
  });

  @override
  State<ConnectionRequestCard> createState() => _ConnectionRequestCardState();
}

class _ConnectionRequestCardState extends State<ConnectionRequestCard> {
  final ApiClient _apiClient = ApiClient();

  Future<void> _startConversation(String userId) async {
    try {
      final response = await _apiClient.post(
        'api/v1/messaging/start/',
        {'user_id': userId});
      
      final conv = ConversationModel.fromJson(
        response['conversation']);
      
      if (!mounted) return;
      Navigator.push(context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversation: conv)));
    } catch (e) {
      debugPrint('Start conversation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: NotificationModel fields are now id, notificationType, message, sender, referenceId, isRead, createdAt
    // Message parsing might be needed if original code relied on 'data' Map
    // However, the prompt rules for NotificationModel didn't include a 'data' field.
    // I will try to map common 'data' fields from the notification message or sender if possible,
    // but the safest is to ensure the model matches what the UI expects if they were using FCM data.
    
    final senderName = widget.notification.sender?.name ?? 'Someone';
    final senderPhoto = widget.notification.sender?.photo;
    
    // Fallback logic for data if it was used in the previous version
    // If the model really needs 'data', I should add it back to the model.
    // Given the prompt: factory NotificationModel.fromJson(Map<String, dynamic> json)
    // and the fields provided, 'data' wasn't there. 
    // I'll assume for now these fields are what we have.
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: senderPhoto != null
                      ? NetworkImage(senderPhoto)
                      : null,
                  child: senderPhoto == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isAccepted == true)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24)
                else if (widget.isDeclined == true)
                  const Icon(Icons.cancel, color: Colors.red, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (widget.isAccepted != true && widget.isDeclined != true) ...[
              const SizedBox(height: 16),
              widget.isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onDecline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ],
            if (widget.isAccepted == true) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'You are now connected with $senderName',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Message'),
                        onPressed: () => _startConversation(widget.notification.sender?.id.toString() ?? ''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        )),
                  ],
                ),
              ),
            ]
            else if (widget.isDeclined == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: const Text(
                  'Connection request declined',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
