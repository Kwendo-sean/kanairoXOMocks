import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DeescalationToolsCard extends StatelessWidget {
  const DeescalationToolsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                PhosphorIcon(PhosphorIcons.handPalm, color: AppConstants.primaryRed, size: 28),
                SizedBox(width: 12),
                Text(
                  'De-escalation Tools',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTool(context, icon: PhosphorIcons.timer, title: 'Take a 20-Minute Timeout', subtitle: 'Pause the conversation and cool down.'),
            const Divider(height: 24),
            _buildTool(context, icon: PhosphorIcons.wind, title: 'Breathing Sync Exercise', subtitle: 'A guided exercise to calm your bodies.'),
            const Divider(height: 24),
            _buildTool(context, icon: PhosphorIcons.quotes, title: '"Remember Why" Prompt', subtitle: 'Revisit a positive memory together.'),
          ],
        ),
      ),
    );
  }

  Widget _buildTool(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
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
              Text(subtitle, style: const TextStyle(color: AppConstants.secondaryGray, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppConstants.secondaryGray),
      ],
    );
  }
}
