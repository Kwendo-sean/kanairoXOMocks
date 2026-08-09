import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/auth/verify_email_screen.dart';
import 'package:kanairoxo/screens/couples/couple_home_screen.dart';
import 'package:kanairoxo/screens/main_app_screen.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Still checking stored token on app launch
        if (auth.isLoading) {
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

        // Not logged in → go to login
        if (!auth.isAuthenticated) {
          return LoginScreen(
            onLoginSuccess: () {},
            onSignupTap: () => Navigator.pushNamed(context, '/signup'),
          );
        }

        // Signed in but email not verified yet.
        //
        // This lives in the gate rather than in the signup flow on purpose:
        // it catches the user who kills the app on the OTP screen and
        // reopens it, which any signup-only redirect would walk straight
        // past. The backend now 403s every real endpoint until this is
        // done, so skipping it just produced an app full of errors.
        final user = auth.user;
        if (user != null && !user.isVerified) {
          return VerifyEmailScreen(
            email: user.email ?? '',
            onVerified: () => auth.refreshProfile(),
          );
        }

        // Logged in as couple account
        if (auth.isCoupleAccount) {
          return CoupleHomeScreen();
        }

        // Default: single or searching account
        return const MainAppScreen();
      },
    );
  }
}
