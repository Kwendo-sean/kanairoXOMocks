import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DateStats extends StatelessWidget {
  const DateStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
              'Date Insights',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  icon: PhosphorIcons.calendar(PhosphorIconsStyle.fill),
                  value: '12', // Example
                  label: 'Total Dates',
                  color: AppConstants.primaryRed,
                ),
                _buildStat(
                  icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                  value: '4.2', // Example
                  label: 'Avg. Rating',
                  color: Colors.amber,
                ),
                _buildStat(
                  icon: PhosphorIcons.binoculars(PhosphorIconsStyle.fill),
                  value: 'Adventure', // Example
                  label: 'Top Category',
                  color: Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.1),
          child: PhosphorIcon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppConstants.secondaryGray, fontSize: 12),
        ),
      ],
    );
  }
}
