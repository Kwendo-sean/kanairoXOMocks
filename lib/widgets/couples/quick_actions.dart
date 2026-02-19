import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickActionButton(
          icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
          label: 'Check-in',
        ),
        _QuickActionButton(
          icon: PhosphorIcons.calendarPlus(PhosphorIconsStyle.regular),
          label: 'Plan Date',
        ),
        _QuickActionButton(
          icon: PhosphorIcons.camera(PhosphorIconsStyle.regular),
          label: 'Add Memory',
        ),
        _QuickActionButton(
          icon: PhosphorIcons.wrench(PhosphorIconsStyle.regular),
          label: 'Repair',
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;

  const _QuickActionButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
          child: PhosphorIcon(
            icon,
            color: AppConstants.primaryRed,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
