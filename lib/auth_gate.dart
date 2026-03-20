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

    if (!_splashFinished && !authProvider.isAuthenticated) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
