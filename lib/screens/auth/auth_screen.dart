import 'package:flutter/material.dart';
import 'package:kanairoxo/screens/auth/login_screen.dart';
import 'package:kanairoxo/screens/auth/signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(
        onLoginSuccess: () {
          // Handled by AuthGate
        },
        onSignupTap: _toggleView,
      );
    } else {
      return SignupScreen(
        onSignupSuccess: () {
          // Handled by AuthGate
        },
        onLoginTap: _toggleView,
      );
    }
  }
}