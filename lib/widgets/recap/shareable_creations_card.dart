import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ShareableCreationsCard extends StatelessWidget {
  const ShareableCreationsCard({super.key});

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
                PhosphorIcon(PhosphorIcons.export(PhosphorIconsStyle.fill), color: AppConstants.primaryRed, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Share Your Story',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildShareOption(context, icon: PhosphorIcons.filePdf(PhosphorIconsStyle.regular), title: 'Export as PDF Book'),
            const Divider(height: 24),
            _buildShareOption(context, icon: PhosphorIcons.video(PhosphorIconsStyle.regular), title: 'Create Video Montage'),
            const Divider(height: 24),
            _buildShareOption(context, icon: PhosphorIcons.image(PhosphorIconsStyle.regular), title: 'Generate Social Media Post'),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, {required IconData icon, required String title}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
          child: PhosphorIcon(icon, color: AppConstants.primaryRed, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const Icon(Icons.chevron_right, color: AppConstants.secondaryGray),
      ],
    );
  }
}
