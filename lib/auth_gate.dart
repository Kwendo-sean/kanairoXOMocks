import 'package:flutter/material.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/screens/auth/splash_screen.dart';
import 'package:kanairoxo/screens/couples/couple_home_screen.dart';
import 'package:kanairoxo/screens/couples/partner_selection_screen.dart';
import 'package:kanairoxo/screens/main_app_screen.dart';
import 'package:kanairoxo/screens/onboarding/onboarding_screen.dart';
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
    if (!_splashFinished) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      // Show a loading screen while checking auth status post-splash
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return OnboardingScreen(
        onComplete: () {
          // Using a named route ensures consistency with your app's navigation
          Navigator.of(context).pushReplacementNamed('/signup');
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
      // For single accounts, navigate to the main app screen
      return const MainAppScreen();
    }
  }
}
