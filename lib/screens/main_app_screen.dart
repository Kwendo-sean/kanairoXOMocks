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

  // Bumping these keys forces the child screen to rebuild from scratch — a true reload.
  final List<int> _reloadKeys = List<int>.filled(5, 0);

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

  Widget _screenAt(int i) {
    final key = ValueKey('tab_${i}_${_reloadKeys[i]}');
    switch (i) {
      case 0: return DiscoveryScreen(key: key);
      case 1: return EventsScreenWrapper(key: key);
      case 2: return MomentsScreen(key: key);
      case 3: return ConversationsScreen(key: key);
      case 4: return ProfileScreen(key: key);
      default: return const SizedBox.shrink();
    }
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) {
      // Re-tap on the active tab — reload that screen
      setState(() => _reloadKeys[index]++);
      return;
    }
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
        body: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemCount: 5,
          itemBuilder: (_, i) => _screenAt(i),
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
