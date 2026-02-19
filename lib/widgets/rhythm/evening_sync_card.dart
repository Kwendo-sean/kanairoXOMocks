import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EveningSyncCard extends StatelessWidget {
  const EveningSyncCard({super.key});

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
                PhosphorIcon(PhosphorIcons.moon(PhosphorIconsStyle.fill), color: Colors.indigo, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Evening Sync',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                Text('Yesterday', style: TextStyle(color: AppConstants.secondaryGray, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Review your day (highs & lows).'),
            // Placeholder
            const SizedBox(height: 16),
            const Text('How was your connection quality?'),
            // Placeholder
            const SizedBox(height: 16),
            const Text('Share something you\'re grateful for.'),
            // Placeholder
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppConstants.primaryRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('View Sync', style: TextStyle(color: AppConstants.primaryRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
