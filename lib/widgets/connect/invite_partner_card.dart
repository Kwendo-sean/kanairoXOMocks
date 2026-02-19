import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class InvitePartnerCard extends StatelessWidget {
  const InvitePartnerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppConstants.primaryRed,
              child: PhosphorIcon(
                PhosphorIcons.userPlus(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Invite Your Partner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share a unique code to connect your accounts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.secondaryGray, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: const Text(
                'Generate Connection Code',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
