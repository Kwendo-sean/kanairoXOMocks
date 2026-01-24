import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/connection_provider.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/auth/signup_screen.dart';
import 'package:kanairoxo/screens/auth/splash_screen.dart';
import 'package:kanairoxo/screens/discovery_screen.dart';
import 'package:kanairoxo/screens/events/event_detail_screen.dart';
import 'package:kanairoxo/screens/events/event_memories_screen.dart';
import 'package:kanairoxo/screens/events/events_screen.dart';
import 'package:kanairoxo/screens/events/host_event_screen.dart';
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
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/bottom_nav_bar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/screens/events/events_screen.dart';

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
          update: (_, auth, previous) =>
              (previous ?? ProfileProvider())..update(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EventsProvider>(
          create: (_) => EventsProvider(),
          update: (_, auth, previous) =>
              (previous ?? EventsProvider())..update(auth),
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
          textTheme: GoogleFonts.nunitoTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AppWrapper(),
        routes: {
          '/onboarding': (context) => OnboardingScreen(
                onComplete: () {
                  Navigator.pushReplacementNamed(context, '/signup');
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
                  Navigator.pushReplacementNamed(context, '/main');
                },
                onLoginTap: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
          '/main': (context) => const MainAppScreen(),
          '/events': (context) => const EventsScreenWrapper(),
          '/events/host': (context) => HostEventScreen(
            onEventCreated: (event) {
              // Refresh events list
              context.read<EventsProvider>().fetchExperiences();
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
               Navigator.pop(context);
            },
          ),
          '/events/:id': (context) {
            final eventId = ModalRoute.of(context)!.settings.arguments as String;
            return EventDetailScreen(eventId: eventId);
          },
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
  bool _hasCompletedOnboarding = false; // You might need to persist this

  @override
  void initState() {
    super.initState();
    // TODO: You should persist and retrieve this value
    const hasCompletedOnboarding = false;
    _hasCompletedOnboarding = hasCompletedOnboarding;
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

    final auth = context.watch<AuthProvider>();

    if (auth.isAuthenticated) {
      return const MainAppScreen();
    }

    if (!_hasCompletedOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          if (mounted) {
            // Update state and navigate to signup
            setState(() {
              _hasCompletedOnboarding = true;
            });
            Navigator.pushReplacementNamed(context, '/signup');
          }
        },
      );
    }

    return LoginScreen(
      onLoginSuccess: () {
        // This is handled by the provider state change now.
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
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/login', (route) => false);
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
              icon:
                  PhosphorIcon(PhosphorIcons.plus(PhosphorIconsStyle.regular)),
              label: const Text('New Story'),
            )
          : null,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        onSettingsLongPress: _navigateToSettings,
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
            Navigator.pushNamed(context, '/events/:id',
                arguments: experience.id);
          },
        );
      },
    );
  }
}
