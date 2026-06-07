import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onSettingsLongPress;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onSettingsLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color activeColor = isDark 
        ? const Color(0xFFC0394B) 
        : AppColors.primary;
    final Color inactiveColor = isDark 
        ? const Color(0xFF7A6E66) 
        : AppColors.textMuted;
    final Color bgColor = isDark 
        ? const Color(0xFF1C1612) 
        : AppColors.surfaceGlass;
    final Color borderColor = isDark 
        ? const Color(0xFF2E2820) 
        : Colors.white.withOpacity(0.5);

    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: GestureDetector(
              // Swipe horizontally across the nav itself to switch tabs.
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v.abs() < 100) return; // ignore tiny flicks
                if (v < 0 && currentIndex < 4) {
                  onTap(currentIndex + 1);          // swipe left → next tab
                } else if (v > 0 && currentIndex > 0) {
                  onTap(currentIndex - 1);          // swipe right → prev tab
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.all(Radius.circular(32)),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(context, 0, PhosphorIcons.compass(PhosphorIconsStyle.regular), 'Discover', activeColor, inactiveColor),
                    _buildNavItem(context, 1, PhosphorIcons.calendar(PhosphorIconsStyle.regular), 'Events', activeColor, inactiveColor),
                    _buildNavItem(context, 2, PhosphorIcons.sparkle(PhosphorIconsStyle.regular), 'Moments', activeColor, inactiveColor),
                    _buildNavItem(context, 3, PhosphorIcons.chatsCircle(PhosphorIconsStyle.regular), 'Messages', activeColor, inactiveColor),
                    _buildNavItem(context, 4, PhosphorIcons.user(PhosphorIconsStyle.regular), 'Profile', activeColor, inactiveColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, Color activeColor, Color inactiveColor) {
    final isActive = index == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      onLongPress: index == 4 ? onSettingsLongPress : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              icon,
              size: 24,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
