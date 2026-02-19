import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/connection_provider.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/screens/auth/auth_gate.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/auth/signup_screen.dart';
import 'package:kanairoxo/screens/couples/couple_home_screen.dart';
import 'package:kanairoxo/screens/discovery_screen.dart';
import 'package:kanairoxo/screens/events/events_screen.dart';
import 'package:kanairoxo/screens/mood_screen.dart';
import 'package:kanairoxo/screens/onboarding/onboarding_screen.dart';
import 'package:kanairoxo/screens/profile/profile_screen.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const KanairoXOApp());
}

class KanairoXOApp extends StatelessWidget {
  const KanairoXOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(),
          update: (_, auth, previous) => (previous ?? ProfileProvider())..update(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EventsProvider>(
          create: (_) => EventsProvider(),
          update: (_, auth, previous) => (previous ?? EventsProvider())..update(auth),
        ),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => ConnectionProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: AppConstants.appName,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppConstants.primaryBeige,
          colorScheme: const ColorScheme.light(
            primary: AppConstants.primaryRed,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppConstants.primaryBlack,
            secondary: AppConstants.secondaryGray,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
        routes: {
          '/onboarding': (context) => OnboardingScreen(onComplete: () => Navigator.pushReplacementNamed(context, '/signup')),
          '/login': (context) => LoginScreen(onLoginSuccess: () {}, onSignupTap: () => Navigator.pushNamed(context, '/signup')),
          '/signup': (context) => SignupScreen(onSignupSuccess: () {}, onLoginTap: () => Navigator.pushNamed(context, '/login')),
          '/main_single': (context) => const MainAppScreen(),
          '/main_couple': (context) => CoupleHomeScreen(),
        },
      ),
    );
  }
}

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
    const EventsScreenWrapper(), // Correctly using the wrapper now
    MoodScreen(onMoodSelected: (mood) {}, onContinue: () {}),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
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

// This wrapper was already defined and is now being correctly used.
class EventsScreenWrapper extends StatelessWidget {
  const EventsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        return EventsScreen(
          onJoinExperience: (experience) {
            Navigator.pushNamed(context, '/payment', arguments: {
              'amount': experience.priceDisplay, 'eventName': experience.title, 'eventDate': experience.formattedDate,
            });
          },
          onExperienceSelected: (experience) {
            Navigator.pushNamed(context, '/events/:id', arguments: experience.id);
          },
        );
      },
    );
  }
}
