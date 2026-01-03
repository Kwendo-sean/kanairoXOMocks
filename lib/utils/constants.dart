import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryBeige = Color(0xFFF5F1EA);
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color primaryRed = Color(0xFF8B0000);
  static const Color secondaryGray = Color(0xFF8B7355);
  static const Color lightGray = Color(0xFFE0D7CC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningAmber = Color(0xFFF57C00);
  
  // Durations
  static const Duration splashDuration = Duration(seconds: 7);
  static const Duration messageDisappearDuration = Duration(hours: 48);
  static const Duration storyDuration = Duration(hours: 12);
  
  // App Settings
  static const String appName = 'KanairoXO';
  static const double defaultBorderRadius = 20.0;
  static const double cardBorderRadius = 24.0;
  static const double buttonBorderRadius = 28.0;
  
  // Animation Durations
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);
}

class AppStrings {
  static const String appTagline = 'Meaningful connections, curated moments';
  static const String discoverTitle = 'Discover';
  static const String eventsTitle = 'Experiences';
  static const String moodTitle = 'Mood';
  static const String messagesTitle = 'Messages';
  static const String notificationsTitle = 'Notifications';
  static const String profileTitle = 'Profile';
  
  // Auth
  static const String login = 'Log In';
  static const String signup = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String phoneNumber = 'Phone Number';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = 'Don\'t have an account? ';
  static const String hasAccount = 'Already have an account? ';
}