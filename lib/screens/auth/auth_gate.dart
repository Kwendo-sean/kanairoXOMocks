import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/couples/couple_home_screen.dart';
import 'package:kanairoxo/app.dart'; // For MainAppScreen

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Still checking stored token on app launch
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in → go to login
        if (!auth.isAuthenticated) {
          return LoginScreen(
            onLoginSuccess: () {},
            onSignupTap: () => Navigator.pushNamed(context, '/signup'),
          );
        }

        // Logged in as couple account
        if (auth.isCoupleAccount) {
          // Couples always have a partner (created during registration)
          // Just route to couple home
          return CoupleHomeScreen(); // Removed const
        }

        // Default: single or searching account
        return const MainAppScreen();
      },
    );
  }
}
