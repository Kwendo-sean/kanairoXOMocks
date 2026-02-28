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
  static const Color warningOrange = Color(0xFFFFA726);

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

  // Cache Keys
  static const String eventsCacheKey = 'cached_events';
  static const String categoriesCacheKey = 'cached_categories';
}

class AppStrings {
  // Auth
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String phoneNumber = 'Phone Number';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String termsAndConditions = 'Terms & Conditions';
  static const String privacyPolicy = 'Privacy Policy';
  static const String acceptTerms = 'I agree to the Terms & Conditions';
  static const String acceptPrivacy = 'I agree to the Privacy Policy';
  static const String gender = 'Gender';
  static const String dateOfBirth = 'Date of Birth';
  static const String optional = 'Optional';

  // Notifications
  static const String notificationsTitle = 'Notifications';

  // Validation messages
  static const String passwordMismatch = 'Passwords do not match';
  static const String acceptTermsError = 'You must accept terms and privacy policy';
  static const String phoneValidation = 'Please enter a valid Kenyan phone number';
}

class ApiConstants {
  // Must match ApiClient.baseUrl. Always use HTTPS in production.
  static const String baseUrl = 'https://api.kanairoxo.com';
  static const int timeout = 30; // seconds
}
