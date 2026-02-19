import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ConnectionStreakCard extends StatelessWidget {
  const ConnectionStreakCard({super.key});

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  PhosphorIcons.fire(PhosphorIconsStyle.fill),
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '12', // Example value
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Day Streak',
              style: TextStyle(
                color: AppConstants.secondaryGray,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
