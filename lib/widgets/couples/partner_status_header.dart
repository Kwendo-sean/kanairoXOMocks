import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PartnerStatusHeader extends StatelessWidget {
  const PartnerStatusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPartnerStatus(
            name: 'You',
            avatarUrl: 'https://via.placeholder.com/150', // Placeholder
            isOnline: true,
            moodEmoji: '😊',
          ),
          PhosphorIcon(
            PhosphorIcons.heart(PhosphorIconsStyle.fill),
            color: AppConstants.primaryRed,
            size: 32,
          ),
          _buildPartnerStatus(
            name: 'Jane Doe', // Placeholder
            avatarUrl: 'https://via.placeholder.com/150', // Placeholder
            isOnline: false,
            moodEmoji: '😴',
            lastActive: '2h ago',
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerStatus({
    required String name,
    required String avatarUrl,
    required bool isOnline,
    required String moodEmoji,
    String? lastActive,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundColor: AppConstants.lightGray,
              // backgroundImage: NetworkImage(avatarUrl),
            ),
            Positioned(
              bottom: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(moodEmoji, style: const TextStyle(fontSize: 16)),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (lastActive != null) ...[
          const SizedBox(height: 2),
          Text(
            lastActive,
            style: const TextStyle(fontSize: 12, color: AppConstants.secondaryGray),
          ),
        ]
      ],
    );
  }
}
