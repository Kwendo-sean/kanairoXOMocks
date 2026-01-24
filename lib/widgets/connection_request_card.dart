// lib/widgets/connection_request_card.dart
import 'package:flutter/material.dart';
import 'package:kanairoxo/models/notification_model.dart';

class ConnectionRequestCard extends StatelessWidget {
  final Notification notification;
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
  Widget build(BuildContext context) {
    final senderName = notification.data['sender_name'] ?? 'Someone';
    final senderPhoto = notification.data['sender_photo'];
    final requestMessage = notification.data['request_message'];
    final compatibilityScore = notification.data['compatibility_score'];
    final mutualInterests = (notification.data['mutual_interests'] as List?)?.cast<String>() ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sender info
            Row(
              children: [
                // Profile picture
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

                // Sender info
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
                      if (compatibilityScore != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCompatibilityColor(compatibilityScore.toDouble()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${compatibilityScore.toInt()}% Match',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Status indicator
                if (isAccepted == true)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24)
                else if (isDeclined == true)
                  const Icon(Icons.cancel, color: Colors.red, size: 24),
              ],
            ),

            // Request message
            if (requestMessage != null && requestMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  requestMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],

            // Mutual interests
            if (mutualInterests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Mutual Interests',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: mutualInterests.take(5).map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Colors.blue[50],
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            // Action buttons
            if (isAccepted != true && isDeclined != true) ...[
              const SizedBox(height: 16),
              isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                children: [
                  // Accept button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
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

                  // Decline button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDecline,
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

            // Status message
            if (isAccepted == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'You are now connected with $senderName',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (isDeclined == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Connection request declined',
                  style: const TextStyle(
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

  Color _getCompatibilityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}