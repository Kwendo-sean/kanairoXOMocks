import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// iOS 26-style liquid-glass tab bar. Floating pill, icon-only with an inflated
/// pill highlight around the active tab.
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

  static const _accent = Color(0xFF9B111E);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = isDark ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.55);
    final glass = isDark
      ? Colors.white.withOpacity(0.06)
      : Colors.white.withOpacity(0.55);
    final border = isDark
      ? Colors.white.withOpacity(0.08)
      : Colors.white.withOpacity(0.7);

    final items = <_NavItemData>[
      _NavItemData(PhosphorIcons.compass(PhosphorIconsStyle.regular),
                   PhosphorIcons.compass(PhosphorIconsStyle.fill), 'Discover'),
      _NavItemData(PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                   PhosphorIcons.calendar(PhosphorIconsStyle.fill), 'Events'),
      _NavItemData(PhosphorIcons.sparkle(PhosphorIconsStyle.regular),
                   PhosphorIcons.sparkle(PhosphorIconsStyle.fill), 'Moments'),
      _NavItemData(PhosphorIcons.chatsCircle(PhosphorIconsStyle.regular),
                   PhosphorIcons.chatsCircle(PhosphorIconsStyle.fill), 'Messages'),
      _NavItemData(PhosphorIcons.user(PhosphorIconsStyle.regular),
                   PhosphorIcons.user(PhosphorIconsStyle.fill), 'Profile'),
    ];

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: glass,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                    blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (i) {
                  return _NavItem(
                    data: items[i],
                    selected: i == currentIndex,
                    accent: _accent,
                    inactive: inactive,
                    onTap: () => onTap(i),
                    onLongPress: i == 4 ? onSettingsLongPress : null);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData regular;
  final IconData fill;
  final String label;
  _NavItemData(this.regular, this.fill, this.label);
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool selected;
  final Color accent;
  final Color inactive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.accent,
    required this.inactive,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          PhosphorIcon(
            selected ? data.fill : data.regular,
            size: 22,
            color: selected ? Colors.white : inactive),
          if (selected) ...[
            const SizedBox(width: 6),
            Text(data.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }
}
