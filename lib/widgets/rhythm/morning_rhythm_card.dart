import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MorningRhythmCard extends StatelessWidget {
  const MorningRhythmCard({super.key});

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
                PhosphorIcon(PhosphorIcons.sunrise(PhosphorIconsStyle.fill), color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Morning Rhythm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                Text('Today', style: TextStyle(color: AppConstants.secondaryGray, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('How did you sleep?'),
            // Placeholder for sleep quality rating
            const SizedBox(height: 16),
            const Text('What\'s your energy forecast?'),
            // Placeholder for energy forecast
            const SizedBox(height: 16),
             const Text('What are your intentions for the day?'),
            // Placeholder for intentions
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Begin Check-in', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
