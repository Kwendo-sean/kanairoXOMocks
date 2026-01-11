// lib/widgets/profile/interests_grid.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';

class InterestsGrid extends StatelessWidget {
  final List<String> interests;
  final bool editable;
  final Function(String)? onRemove;
  final Function()? onAdd;

  const InterestsGrid({
    super.key,
    required this.interests,
    this.editable = false,
    this.onRemove,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Interests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (editable && onAdd != null)
              IconButton(
                onPressed: onAdd,
                icon: PhosphorIcon(
                  PhosphorIcons.plusCircle(PhosphorIconsStyle.regular),
                  color: AppConstants.primaryRed,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (interests.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                PhosphorIcon(
                  PhosphorIcons.heart(PhosphorIconsStyle.regular),
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No interests added yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                if (editable) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Add some interests to show people what you love!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...interests.map((interest) {
                return Chip(
                  label: Text(interest),
                  backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
                  deleteIcon: editable && onRemove != null
                      ? PhosphorIcon(
                    PhosphorIcons.x(PhosphorIconsStyle.regular),
                    size: 14,
                  )
                      : null,
                  onDeleted: editable && onRemove != null
                      ? () => onRemove!(interest)
                      : null,
                );
              }).toList(),

              if (editable && onAdd != null)
                ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.plus(PhosphorIconsStyle.regular),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text('Add'),
                    ],
                  ),
                  onPressed: onAdd,
                  backgroundColor: Colors.grey[100],
                ),
            ],
          ),
      ],
    );
  }
}