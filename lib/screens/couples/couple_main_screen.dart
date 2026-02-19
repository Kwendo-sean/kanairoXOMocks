import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/screens/couple/couple_home_screen.dart';
import 'package:kanairoxo/screens/couple/dates_screen.dart';
import 'package:kanairoxo/screens/couple/memories_screen.dart';
import 'package:kanairoxo/screens/couple/couple_events_screen.dart';
import 'package:kanairoxo/screens/couple/couple_chat_screen.dart';

class CoupleMainScreen extends StatefulWidget {
  const CoupleMainScreen({super.key});

  @override
  State<CoupleMainScreen> createState() => _CoupleMainScreenState();
}

class _CoupleMainScreenState extends State<CoupleMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CoupleHomeScreen(),
    const DatesScreen(),
    const MemoriesScreen(),
    const CoupleEventsScreen(),
    const CoupleChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  0,
                  'Home',
                  PhosphorIcons.house(PhosphorIconsStyle.regular),
                  PhosphorIcons.house(PhosphorIconsStyle.fill),
                ),
                _buildNavItem(
                  1,
                  'Dates',
                  PhosphorIcons.calendarHeart(PhosphorIconsStyle.regular),
                  PhosphorIcons.calendarHeart(PhosphorIconsStyle.fill),
                ),
                _buildNavItem(
                  2,
                  'Memories',
                  PhosphorIcons.images(PhosphorIconsStyle.regular),
                  PhosphorIcons.images(PhosphorIconsStyle.fill),
                ),
                _buildNavItem(
                  3,
                  'Events',
                  PhosphorIcons.ticket(PhosphorIconsStyle.regular),
                  PhosphorIcons.ticket(PhosphorIconsStyle.fill),
                ),
                _buildNavItem(
                  4,
                  'Chat',
                  PhosphorIcons.chatCircle(PhosphorIconsStyle.regular),
                  PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index,
      String label,
      PhosphorIconData icon,
      PhosphorIconData activeIcon,
      ) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppConstants.primaryRed : AppConstants.secondaryGray;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                isActive ? activeIcon : icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}