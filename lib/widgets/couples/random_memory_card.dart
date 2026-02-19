import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RandomMemoryCard extends StatelessWidget {
  const RandomMemoryCard({super.key});

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
            PhosphorIcon(
              PhosphorIcons.shuffle(PhosphorIconsStyle.regular),
              color: AppConstants.primaryRed,
              size: 28,
            ),
            const SizedBox(height: 8),
            const Text(
              'Surprise!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pull a random memory',
              textAlign: TextAlign.center,
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
