import 'package:flutter/material.dart';
import 'package:kanairoxo/screens/auth/splash_screen.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/auth/signup_screen.dart';
import 'package:kanairoxo/screens/onboarding/onboarding_screen.dart';
import 'package:kanairoxo/screens/discovery_screen.dart';
import 'package:kanairoxo/screens/events_screen.dart';
import 'package:kanairoxo/screens/mood_screen.dart';
import 'package:kanairoxo/screens/messages/messages_screen.dart';
import 'package:kanairoxo/screens/notification_screen.dart';
import 'package:kanairoxo/screens/messages/chat_screen.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';
import 'package:kanairoxo/screens/profile/settings_screen.dart';
import 'package:kanairoxo/screens/post_story_screen.dart';
import 'package:kanairoxo/screens/payment/payment_screen.dart';

import 'package:kanairoxo/screens/event_memories_screen.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/models/message_model.dart';
import 'package:kanairoxo/models/notification_model.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart' show Badge;

void main() {
  runApp(const KanairoXOApp());
}

class KanairoXOApp extends StatelessWidget {
  const KanairoXOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        fontFamily: 'Inter',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AppWrapper(),
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
        '/onboarding': (context) => OnboardingScreen(
              onComplete: () {
                Navigator.pushReplacementNamed(context, '/main');
              },
            ),
        '/main': (context) => const MainAppScreen(),
        '/chat': (context) => ChatScreen(
              chat: Chat(
                id: '1',
                userId: 'user1',
                userName: 'Sofia',
                userImage:
                    'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop',
                lastMessage: 'Looking forward to seeing you!',
                lastMessageTime: DateTime.now(),
                unreadCount: 2,
                isOnline: true,
              ),
            ),
        '/notifications': (context) => const NotificationScreen(),
        '/profile-edit': (context) => ProfileEditorScreen(
              user: User(
                id: 'current_user',
                email: 'user@example.com',
                firstName: 'John',
                lastName: 'Doe',
                phoneNumber: '0712345678',
                gender: 'Male',
                createdAt: DateTime.now(),
                profileImageUrl:
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&h=400&fit=crop',
                interests: ['Coffee', 'Art', 'Travel'],
                location: 'Nairobi, Kenya',
              ),
            ),
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
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Simulate network check
    await Future.delayed(const Duration(seconds: 2));
    
    // TODO: Replace with actual auth check
    final isLoggedIn = false; // Change based on actual auth state
    final hasCompletedOnboarding = false; // Check from shared preferences
    
    setState(() {
      _isLoading = false;
      _isLoggedIn = isLoggedIn;
      _hasCompletedOnboarding = hasCompletedOnboarding;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      return SplashScreen(
        onComplete: () {
          setState(() {
            _splashComplete = true;
          });
        },
      );
    }
    if (_isLoading) {
      // Optionally show a loading indicator
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            _isLoggedIn = true;
          });
        },
        onSignupTap: () {
          Navigator.pushNamed(context, '/signup');
        },
      );
    }
    if (!_hasCompletedOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          setState(() {
            _hasCompletedOnboarding = true;
          });
        },
      );
    }
    return const MainAppScreen();
  }
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _showMessagesDrawer = false;

  List<Widget> _buildScreens(BuildContext context) {
    return [
      DiscoveryScreen(
        onConnect: () {
          // Handle connect action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection request sent'),
              backgroundColor: AppConstants.primaryRed,
            ),
          );
        },
        onNotNow: () {
          // Handle not now action
        },
        onNextProfile: () {
          // Handle next profile action
        },
      ),
      EventsScreen(
        onJoinExperience: _handleJoinExperience,
        onExperienceSelected: (experience) {
          // Handle experience selection
        },
      ),
      MoodScreen(
        onMoodSelected: (mood) {
          // Handle mood selection
        },
        onContinue: () {
          // Handle continue
        },
      ),
      Container(
        color: AppConstants.primaryBeige,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&h=400&fit=crop'),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to view and edit your profile',
                style: TextStyle(
                  color: AppConstants.secondaryGray,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Navigate to profile editor
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _openMessages() {
    setState(() => _showMessagesDrawer = true);
  }

  void _closeMessages() {
    setState(() => _showMessagesDrawer = false);
  }

  void _navigateToPayment() {
    Navigator.pushNamed(context, '/payment');
  }



  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  void _navigateToPostStory() {
    Navigator.pushNamed(context, '/post-story');
  }



  void _handleJoinExperience(Experience experience) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join Experience'),
          content: Text('Join "${experience.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Join & Pay'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: _buildScreens(context),
          ),

          // Messages drawer overlay
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 20 && !_showMessagesDrawer) {
                  _openMessages();
                }
                if (details.delta.dx < -20 && _showMessagesDrawer) {
                  _closeMessages();
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),

          // Messages screen overlay (drawer)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _showMessagesDrawer ? 0 : -MediaQuery.of(context).size.width,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width,
            child: Material(
              color: Colors.white,
              child: Column(
                children: [
                  // Messages header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppConstants.lightGray),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _closeMessages,
                          icon:  Icon(PhosphorIcons.x()),
                          color: AppConstants.primaryBlack,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Messages',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            // New message
                          },
                          icon: Icon(PhosphorIcons.plus()),
                          color: AppConstants.primaryBlack,
                        ),
                      ],
                    ),
                  ),

                  // Messages content
                  const Expanded(
                    child: MessagesScreen(),
                  ),
                ],
              ),
            ),
          ),

          // Messages toggle button (top left)
          if (!_showMessagesDrawer)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: IconButton(
                  onPressed: _openMessages,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Badge(
                      backgroundColor: AppConstants.primaryRed,
                      label: const Text('3'),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          PhosphorIcons.chats(),
                          color: AppConstants.primaryBlack,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Notification toggle button (top right)
          if (!_showMessagesDrawer)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Badge(
                        backgroundColor: AppConstants.primaryRed,
                        label: const Text('12'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            PhosphorIcons.bell(),
                            color: AppConstants.primaryBlack,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _currentIndex == 3 // Profile screen
          ? FloatingActionButton.extended(
              onPressed: _navigateToPostStory,
              backgroundColor: AppConstants.primaryRed,
              foregroundColor: Colors.white,
              icon:  Icon(PhosphorIcons.plus()),
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
          _buildNavItem(0, PhosphorIcons.compass(), 'Discover'),
          _buildNavItem(1, PhosphorIcons.calendar(), 'Events'),
          _buildNavItem(2, PhosphorIcons.moon(), 'Mood'),
          _buildNavItem(3, PhosphorIcons.user(), 'Profile'),
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
            Icon(
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

// Updated Events Screen wrapper to include payment navigation
class EventsScreenWrapper extends StatelessWidget {
  const EventsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return EventsScreen(
      onJoinExperience: (experience) {
        Navigator.pushNamed(
          context,
          '/payment',
          arguments: {
            'amount': experience.price ?? 1500.00,
            'eventName': experience.title,
            'eventDate': experience.dateFormatted,
          },
        );
      },
      onExperienceSelected: (experience) {
        // Handle experience selection
      },
    );
  }
}

// Updated Mood Screen wrapper
class MoodScreenWrapper extends StatelessWidget {
  const MoodScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MoodScreen(
      onMoodSelected: (mood) {
        // Handle mood selection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood set to ${mood.name}. Refreshing your feed...'),
            backgroundColor: AppConstants.primaryRed,
          ),
        );
      },
      onContinue: () {
        // Handle continue
      },
    );
  }
}

// Updated Discovery Screen wrapper
class DiscoveryScreenWrapper extends StatelessWidget {
  const DiscoveryScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return DiscoveryScreen(
      currentProfileIndex: 0,
      onConnect: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request sent'),
            backgroundColor: AppConstants.primaryRed,
          ),
        );
      },
      onNotNow: () {
        // Move to next profile
      },
      onNextProfile: () {
        // Next profile logic
      },
    );
  }
}