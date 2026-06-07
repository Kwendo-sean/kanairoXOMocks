import 'package:flutter/material.dart';
import 'package:kanairoxo/auth_gate.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/theme_provider.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/auth/signup_screen.dart';
import 'package:kanairoxo/screens/couples/couple_home_screen.dart';
import 'package:kanairoxo/screens/couples/partner_selection_screen.dart';
import 'package:kanairoxo/screens/main_app_screen.dart';
import 'package:kanairoxo/screens/notification_screen.dart';
import 'package:kanairoxo/screens/onboarding/new_onboarding_screen.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';
import 'package:kanairoxo/screens/settings/settings_screen.dart';
import 'package:kanairoxo/screens/settings/blocked_accounts_screen.dart';
import 'package:kanairoxo/screens/settings/privacy_settings_screen.dart';
import 'package:kanairoxo/screens/settings/notification_settings_screen.dart';
import 'package:kanairoxo/screens/settings/delete_account_screen.dart';
import 'package:kanairoxo/screens/premium/premium_screen.dart';
import 'package:kanairoxo/screens/messages/date_requests_screen.dart';
import 'package:kanairoxo/screens/messages/date_payment_screen.dart';
import 'package:kanairoxo/models/date_request_model.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/services/deep_links.dart';

// Ticket flow imports
import 'package:kanairoxo/models/ticket_model.dart';
import 'package:kanairoxo/features/tickets/screens/ticket_reveal_screen.dart';
import 'package:kanairoxo/features/tickets/screens/my_tickets_screen.dart';

class KanairoXOApp extends StatefulWidget {
  const KanairoXOApp({super.key});

  @override
  State<KanairoXOApp> createState() => _KanairoXOAppState();
}

class _KanairoXOAppState extends State<KanairoXOApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinks.instance.attach(_navKey);
    });
  }

  @override
  void dispose() {
    DeepLinks.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: _navKey,
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        if (settings.name == '/date-payment') {
          final request = settings.arguments as DateRequestModel;
          return MaterialPageRoute(
            builder: (context) => DatePaymentScreen(request: request),
          );
        }
        if (settings.name == '/ticket-reveal') {
          final ticket = settings.arguments as TicketModel;
          return MaterialPageRoute(
            builder: (context) => TicketRevealScreen(ticket: ticket),
          );
        }
        return null;
      },
      routes: {
        '/onboarding': (context) => const NewOnboardingScreen(),
        '/login': (context) => LoginScreen(
              onLoginSuccess: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
              onSignupTap: () => Navigator.pushNamed(context, '/signup'),
            ),
        '/signup': (context) => SignupScreen(
              onSignupSuccess: () {
                Navigator.pushReplacementNamed(context, '/main_single');
              },
              onLoginTap: () => Navigator.pushNamed(context, '/login'),
            ),
        '/profile_editor': (context) => ProfileEditorScreen(
              onClose: () => Navigator.of(context).pushReplacementNamed('/'),
            ),
        '/partner_selection': (context) => const PartnerSelectionScreen(),
        '/main_single': (context) => const MainAppScreen(),
        '/main_couple': (context) => CoupleHomeScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/settings/blocked': (context) => const BlockedAccountsScreen(),
        '/settings/privacy': (context) => const PrivacySettingsScreen(),
        '/settings/notifications': (context) => const NotificationSettingsScreen(),
        '/settings/delete-account': (context) => const DeleteAccountScreen(),
        '/premium': (context) => const PremiumScreen(),
        '/date-requests': (context) => const DateRequestsScreen(),
        '/my-tickets': (context) => const MyTicketsScreen(),
      },
    );
  }
}
