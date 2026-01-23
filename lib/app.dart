import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/auth/signup_screen.dart';
import 'package:kanairoxo/screens/auth/splash_screen.dart';
import 'package:kanairoxo/screens/discovery_screen.dart';
import 'package:kanairoxo/screens/events/event_memories_screen.dart';
import 'package:kanairoxo/screens/events/events_screen.dart';
import 'package:kanairoxo/screens/messages/chat_screen.dart';
import 'package:kanairoxo/screens/mood_screen.dart';
import 'package:kanairoxo/screens/notification_screen.dart';
import 'package:kanairoxo/screens/onboarding/onboarding_screen.dart';
import 'package:kanairoxo/screens/payment/payment_screen.dart';
import 'package:kanairoxo/screens/post_story_screen.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';
import 'package:kanairoxo/screens/profile/profile_screen.dart';
import 'package:kanairoxo/screens/profile/settings_screen.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/models/message_model.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/services/auth_service.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class KanairoXOApp extends StatelessWidget {
  const KanairoXOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        ChangeNotifierProvider(create: (context) => EventsProvider()),
        // Add other providers here as needed
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
          textTheme: GoogleFonts.nunitoTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AppWrapper(),
        routes: {
          '/onboarding': (context) => OnboardingScreen(
                onComplete: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
          '/login': (context) => LoginScreen(
                onLoginSuccess: () {
                  Navigator.pushReplacementNamed(context, '/main');
                },
                onSignupTap: () {
                  Navigator.pushNamed(context, '/signup');
                },
              ),
          '/signup': (context) => SignupScreen(
                onSignupSuccess: () {
                  Navigator.pushReplacementNamed(context, '/onboarding');
                },
                onLoginTap: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
          '/main': (context) => const MainAppScreen(),
          '/chat': (context) => ChatScreen(
                chat: Chat(
                  id: '1',
                  userId: 'user1',
                  userName: 'Sofia',
                  userImage: 'assets/images/kanairoxo_logo.png',
                  lastMessage: 'Looking forward to seeing you!',
                  lastMessageTime: DateTime.now(),
                  unreadCount: 2,
                  isOnline: true,
                ),
              ),
          '/notifications': (context) => const NotificationScreen(),
          '/profile-edit': (context) => const ProfileEditorScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/post-story': (context) => const PostStoryScreen(),
          '/event-memories': (context) => EventMemoriesScreen(
                eventId: '1',
                eventName: 'Morning Coffee & Conversation',
              ),
          '/payment': (context) => PaymentScreen(
                amount: 1500.00,
                eventName: 'Gallery Opening: New Perspectives',
                eventDate: 'Mon, Jan 6 • 6:30 PM',
              ),
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _splashComplete = false;
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false; // You might need to persist this

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    // TODO: You should persist and retrieve this value
    const hasCompletedOnboarding = false;

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _hasCompletedOnboarding = hasCompletedOnboarding;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      return SplashScreen(
        onComplete: () {
          if (mounted) {
            setState(() {
              _splashComplete = true;
            });
          }
        },
      );
    }

    if (_isLoggedIn) {
      return const MainAppScreen();
    }

    if (!_hasCompletedOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          if (mounted) {
            // Update state and navigate to login
            setState(() {
              _hasCompletedOnboarding = true;
            });
             Navigator.pushReplacementNamed(context, '/login');
          }
        },
      );
    }
    
    return LoginScreen(
      onLoginSuccess: () {
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
          });
        }
      },
      onSignupTap: () {
        Navigator.pushNamed(context, '/signup');
      },
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

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.loadMyProfile();

      final eventsProvider = context.read<EventsProvider>();
      await eventsProvider.fetchExperiences();
    } on AuthException {
      // Handle auth exception during initial data load
      await context.read<ProfileProvider>().handleLogout();
      if (mounted) {
        // Use the global navigator key to navigate
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Handle other potential errors
      print('An error occurred during initial data load: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const DiscoveryScreen(),
    const EventsScreenWrapper(),
    MoodScreen(
      onMoodSelected: (mood) {},
      onContinue: () {},
    ),
    const ProfileScreen(), // This will show current user's profile
  ];

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  void _navigateToPostStory() {
    Navigator.pushNamed(context, '/post-story');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (mounted) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 3
          ? FloatingActionButton.extended(
              onPressed: _navigateToPostStory,
              backgroundColor: AppConstants.primaryRed,
              foregroundColor: Colors.white,
              icon: PhosphorIcon(PhosphorIcons.plus(PhosphorIconsStyle.regular)),
              label: const Text('New Story'),
            )
          : null,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
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
          _buildNavItem(0, PhosphorIcons.compass(PhosphorIconsStyle.regular), 'Discover'),
          _buildNavItem(1, PhosphorIcons.calendar(PhosphorIconsStyle.regular), 'Events'),
          _buildNavItem(2, PhosphorIcons.moon(PhosphorIconsStyle.regular), 'Mood'),
          _buildNavItem(3, PhosphorIcons.user(PhosphorIconsStyle.regular), 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = index == _currentIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      onLongPress: index == 3 ? _navigateToSettings : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

class EventsScreenWrapper extends StatelessWidget {
  const EventsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        return EventsScreen(
          onJoinExperience: (experience) {
            Navigator.pushNamed(
              context,
              '/payment',
              arguments: {
                'amount': experience.priceDisplay,
                'eventName': experience.title,
                'eventDate': experience.formattedDate,
              },
            );
          },
          onExperienceSelected: (experience) {
            // Handle experience selection
          },
        );
      },
    );
  }
}
