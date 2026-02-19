import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ConnectionExercisesCard extends StatelessWidget {
  const ConnectionExercisesCard({super.key});

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
                PhosphorIcon(PhosphorIcons.barbell(PhosphorIconsStyle.fill), color: AppConstants.primaryRed, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Connection Exercises',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Daily Prompt',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConstants.secondaryGray),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share something you appreciate about your partner.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const Divider(height: 32),
            const Text(
              'Weekly Challenge',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConstants.secondaryGray),
            ),
            const SizedBox(height: 8),
            const Text(
              'Practice active listening for 10 minutes straight.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
             const SizedBox(height: 16),
             Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('See More Exercises', style: TextStyle(color: AppConstants.primaryRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
