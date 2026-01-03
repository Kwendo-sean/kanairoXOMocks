import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final List<_NavItem> _items = [
    _NavItem(icon: PhosphorIcons.compass(), label: 'Discover'),
    _NavItem(icon: PhosphorIcons.calendar(), label: 'Events'),
    _NavItem(icon: PhosphorIcons.moon(), label: 'Mood'),
    _NavItem(icon: PhosphorIcons.user(), label: 'Profile'),
  ];

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
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isActive = index == widget.currentIndex;
          
          return GestureDetector(
            onTap: () => widget.onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFF5F1EA) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: isActive ? const Color(0xFF8B0000) : const Color(0xFF8B7355),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: isActive ? const Color(0xFF8B0000) : const Color(0xFF8B7355),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}