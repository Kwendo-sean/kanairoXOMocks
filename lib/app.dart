import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kanairoxo/auth_gate.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/theme_provider.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/auth/signup_screen.dart';
import 'package:kanairoxo/screens/couples/couple_home_screen.dart';
import 'package:kanairoxo/screens/couples/partner_selection_screen.dart';
import 'package:kanairoxo/screens/events/host_event_screen.dart';
import 'package:kanairoxo/screens/main_app_screen.dart';
import 'package:kanairoxo/screens/notification_screen.dart';
import 'package:kanairoxo/screens/onboarding/onboarding_screen.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:provider/provider.dart';

class KanairoXOApp extends StatelessWidget {
  const KanairoXOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
              secondary: AppColors.textSecondary,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            textTheme: GoogleFonts.dmSansTextTheme(),
          ),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const AuthGate(),
          routes: {
            '/onboarding': (context) => OnboardingScreen(onComplete: () => Navigator.pushReplacementNamed(context, '/signup')),
            '/login': (context) => LoginScreen(
                  onLoginSuccess: () {
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  onSignupTap: () => Navigator.pushNamed(context, '/signup'),
                ),
            '/signup': (context) => SignupScreen(
                  onSignupSuccess: () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (authProvider.isCoupleAccount) {
                      Navigator.pushReplacementNamed(context, '/partner_selection');
                    } else {
                      Navigator.pushReplacementNamed(context, '/profile_editor');
                    }
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
            '/events/host': (context) => const HostEventScreen(),
          },
        );
      },
    );
  }
}
