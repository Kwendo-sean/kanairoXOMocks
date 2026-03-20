import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/screens/discovery_screen.dart';
import 'package:kanairoxo/screens/events/events_screen.dart';
import 'package:kanairoxo/screens/moments_screen.dart';
import 'package:kanairoxo/screens/profile/profile_screen.dart';
import 'package:kanairoxo/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/events_provider.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

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
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
