import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/screens/discovery_screen.dart';
import 'package:kanairoxo/screens/events/events_screen.dart';
import 'package:kanairoxo/screens/moments_screen.dart';
import 'package:kanairoxo/screens/profile/profile_screen.dart';
import 'package:kanairoxo/screens/messaging/conversations_screen.dart';
import 'package:kanairoxo/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'dart:io';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const DiscoveryScreen(),
    const EventsScreenWrapper(),
    const MomentsScreen(),
    const ConversationsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // If not on the first tab, go to the first tab instead of exiting
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _pageController.jumpToPage(0);
          });
          return;
        }

        final now = DateTime.now();
        if (_lastPressedAt == null || 
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        exit(0);
      },
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: _screens,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          onSettingsLongPress: () => Navigator.pushNamed(context, '/settings'),
        ),
      ),
    );
  }
}

class EventsScreenWrapper extends StatelessWidget {
  const EventsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        return EventsScreen(
          onJoinExperience: (experience) {
             // Placeholder
          },
          onExperienceSelected: (experience) {
            // Placeholder
          },
        );
      },
    );
  }
}
