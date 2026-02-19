import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SharedGoalsProgressCard extends StatelessWidget {
  const SharedGoalsProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shared Goals',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildGoalProgress(
              title: 'Save for Bali Vacation',
              progress: 0.65,
              icon: PhosphorIcons.airplaneTilt(PhosphorIconsStyle.fill),
              color: Colors.teal,
            ),
            const SizedBox(height: 12),
            _buildGoalProgress(
              title: 'Complete 30-Day Fitness Challenge',
              progress: 0.8,
              icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.fill),
              color: AppConstants.primaryRed,
            ),
            const SizedBox(height: 12),
            _buildGoalProgress(
              title: 'Read a Book Together',
              progress: 0.25,
              icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
              color: Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress({
    required String title,
    required double progress,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PhosphorIcon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppConstants.lightGray,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
