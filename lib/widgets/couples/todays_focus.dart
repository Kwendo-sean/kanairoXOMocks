import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';

class TodaysFocus extends StatelessWidget {
  const TodaysFocus({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppConstants.primaryRed.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: BorderSide(color: AppConstants.primaryRed.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              color: AppConstants.primaryRed,
              size: 28,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Focus',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share one thing you\'re grateful for about your partner.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.secondaryGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
