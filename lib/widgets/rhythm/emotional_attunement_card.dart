import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EmotionalAttunementCard extends StatelessWidget {
  const EmotionalAttunementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              children: [
                PhosphorIcon(PhosphorIcons.smileyWink(PhosphorIconsStyle.fill), color: AppConstants.primaryRed, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Emotional Tune-up',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureRow(icon: PhosphorIcons.planet(PhosphorIconsStyle.regular), title: 'Emotion Wheel', subtitle: 'Visualize your current feelings'),
            const SizedBox(height: 12),
            _buildFeatureRow(icon: PhosphorIcons.person(PhosphorIconsStyle.regular), title: 'Body Scan', subtitle: 'Connect with physical sensations'),
            const SizedBox(height: 12),
            _buildFeatureRow(icon: PhosphorIcons.chats(PhosphorIconsStyle.regular), title: 'Needs Assessment', subtitle: 'Articulate what you need'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
          child: PhosphorIcon(icon, color: AppConstants.primaryRed, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: AppConstants.secondaryGray, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppConstants.secondaryGray),
      ],
    );
  }
}
