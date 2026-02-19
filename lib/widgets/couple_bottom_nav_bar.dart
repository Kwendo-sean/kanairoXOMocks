import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';

class CoupleBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onSettingsLongPress;

  const CoupleBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onSettingsLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, PhosphorIcons.house(PhosphorIconsStyle.regular), 'Dashboard'),
          _buildNavItem(context, 1, PhosphorIcons.calendar(PhosphorIconsStyle.regular), 'Calendar'),
          _buildNavItem(context, 2, PhosphorIcons.camera(PhosphorIconsStyle.regular), 'Memories'),
          _buildNavItem(context, 3, PhosphorIcons.calendarCheck(PhosphorIconsStyle.regular), 'Events'),
          _buildNavItem(context, 4, PhosphorIcons.user(PhosphorIconsStyle.regular), 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      onLongPress: index == 4 ? onSettingsLongPress : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppConstants.primaryBeige : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              icon,
              size: 22,
              color: isActive ? AppConstants.primaryRed : AppConstants.secondaryGray,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppConstants.primaryRed : AppConstants.secondaryGray,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
