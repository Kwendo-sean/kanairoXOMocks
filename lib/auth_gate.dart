import 'package:flutter/material.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/screens/auth/splash_screen.dart';
import 'package:kanairoxo/screens/couples/couple_home_screen.dart';
import 'package:kanairoxo/screens/couples/partner_selection_screen.dart';
import 'package:kanairoxo/screens/main_app_screen.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/onboarding/onboarding_screen.dart';
import 'package:kanairoxo/screens/auth/verify_email_screen.dart';
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
  bool _onboardingComplete = false;
  /// Set when the user backs out of profile setup, so it isn't shown again
  /// for the rest of the session.
  bool _profileSetupDismissed = false;

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
      if (!_onboardingComplete) {
        return OnboardingScreen(
          onComplete: () => setState(() => _onboardingComplete = true),
        );
      }
      return LoginScreen(
        onLoginSuccess: () {},
        onSignupTap: () => Navigator.pushNamed(context, '/signup'),
      );
    }

    // Signed in but not verified yet — the backend 403s every real endpoint
    // until this is done, so anything past here would just be a wall of
    // errors.
    //
    // This belongs in the gate rather than the signup flow: it also catches
    // someone who killed the app on the OTP screen and reopened it, which a
    // signup-only redirect walks straight past. Google users arrive already
    // verified by Google, so they skip it.
    final user = authProvider.user;
    final signedUpWithGoogle = (user?.phoneNumber ?? '').isEmpty ||
        (user?.phoneNumber ?? '').startsWith('+2540');
    if (user != null && !user.isVerified && !signedUpWithGoogle) {
      return VerifyEmailScreen(
        email: user.email ?? '',
        onVerified: () => authProvider.refreshProfile(),
      );
    }

    // Profile setup, only for accounts that just signed up on this run:
    // signup → verify → profile. justRegistered lives in memory, so an
    // existing user reopening the app goes straight through.
    //
    // A photo check alone was wrong: it matched every account without a
    // main photo, so returning users were sent to the editor on every launch.
    //
    // Google users are the separate case — Google gives us no gender, and the
    // app needs one.
    final phone = authProvider.user?.phoneNumber ?? '';
    final gender = authProvider.user?.gender ?? '';
    final isGoogleUser = phone.isEmpty || phone.startsWith('+2540');

    final needsProfile = isGoogleUser
        ? gender.isEmpty
        : authProvider.justRegistered;

    if (needsProfile && !_profileSetupDismissed) {
      return ProfileEditorScreen(
        onClose: () {
          setState(() => _profileSetupDismissed = true);
          authProvider.clearJustRegistered();
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
