import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MilestoneHighlightsCard extends StatelessWidget {
  const MilestoneHighlightsCard({super.key});

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
            const Row(
              children: [
                PhosphorIcon(PhosphorIcons.star(PhosphorIconsStyle.fill), color: AppConstants.primaryRed, size: 28),
                SizedBox(width: 12),
                Text(
                  'Milestone Highlights',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMilestone(icon: PhosphorIcons.airplaneTilt, title: 'First Trip Together', date: 'January 2023'),
            const Divider(height: 24),
            _buildMilestone(icon: PhosphorIcons.house, title: 'Moved In Together', date: 'June 2023'),
            const Divider(height: 24),
            _buildMilestone(icon: PhosphorIcons.ring, title: 'Got Engaged!', date: 'December 2023'),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestone({required IconData icon, required String title, required String date}) {
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
              Text(date, style: const TextStyle(color: AppConstants.secondaryGray, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppConstants.secondaryGray),
      ],
    );
  }
}
