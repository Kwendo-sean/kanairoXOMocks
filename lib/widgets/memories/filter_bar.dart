import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(
          bottom: BorderSide(color: AppConstants.lightGray, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(context, icon: PhosphorIcons.calendar, label: 'Date'),
            _buildFilterChip(context, icon: PhosphorIcons.tag, label: 'Tags'),
            _buildFilterChip(context, icon: PhosphorIcons.smiley, label: 'Mood'),
            _buildFilterChip(context, icon: PhosphorIcons.star(PhosphorIconsStyle.fill), label: 'Favorites', selected: true),
            _buildFilterChip(context, icon: PhosphorIcons.camera, label: 'Photos'),
            _buildFilterChip(context, icon: PhosphorIcons.microphone, label: 'Voice'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, {required IconData icon, required String label, bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        avatar: PhosphorIcon(icon, size: 16, color: selected ? Colors.white : AppConstants.primaryRed),
        label: Text(label),
        selected: selected,
        onSelected: (value) {},
        backgroundColor: AppConstants.primaryRed.withOpacity(0.05),
        selectedColor: AppConstants.primaryRed,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
        shape: StadiumBorder(
          side: BorderSide(color: AppConstants.primaryRed.withOpacity(0.2)),
        ),
        showCheckmark: false,
      ),
    );
  }
}
