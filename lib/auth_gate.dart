import 'package:flutter/material.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/screens/auth/splash_screen.dart';
import 'package:kanairoxo/screens/couples/couple_home_screen.dart';
import 'package:kanairoxo/screens/couples/partner_selection_screen.dart';
import 'package:kanairoxo/screens/main_app_screen.dart';
import 'package:kanairoxo/screens/onboarding/onboarding_screen.dart';
import 'package:kanairoxo/screens/profile/profile_editor_screen.dart';
import 'package:kanairoxo/services/deep_links.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _splashFinished = false;

  @override
  void initState() {
    super.initState();
    // If the user is already authenticated (e.g. returning from login screen),
    // we don't want to show the splash screen again.
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      _splashFinished = true;
    }
  }

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _splashFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Keep the deep-link handler in sync with auth state so pending
    // universal links get flushed once the user signs in.
    final wasAuth = DeepLinks.instance.isAuthenticated;
    DeepLinks.instance.isAuthenticated = authProvider.isAuthenticated;
    if (!wasAuth && authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DeepLinks.instance.flushPending();
      });
    }

    if (!_splashFinished && !authProvider.isAuthenticated) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: context.bgColor,
        body: const Center(
          child: PulsingGlassPlaceholder(
            width: 120,
            height: 120,
            borderRadius: 24,
          ),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return OnboardingScreen(
        onComplete: () {
          Navigator.of(context).pushReplacementNamed('/signup');
        },
      );
    }

    // Only prompt for gender if:
    // 1. Gender is not set AND
    // 2. User signed in with Google (phone starts with +2540 placeholder or is empty)
    final phone = authProvider.user?.phoneNumber ?? '';
    final gender = authProvider.user?.gender ?? '';
    final isGoogleUser = phone.isEmpty || phone.startsWith('+2540');
    if (isGoogleUser && gender.isEmpty) {
      return ProfileEditorScreen(
        onClose: () {
          authProvider.refreshProfile();
        },
      );
    }

    // If authenticated, decide which dashboard to show
    if (authProvider.isCoupleAccount) {
      if (authProvider.selectedPartner == null) {
        return const PartnerSelectionScreen();
      }
      return CoupleHomeScreen();
    } else {
      return const MainAppScreen();
    }
  }
}
