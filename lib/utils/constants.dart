import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'KanairoXO';
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 999.0;
  static const Duration splashDuration = Duration(seconds: 7);
  static const Duration serviceTimeout = Duration(seconds: 20);
  static const Duration messageDisappearDuration = Duration(hours: 48);
  static const Duration storyDuration = Duration(hours: 12);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);
  static const String eventsCacheKey = 'cached_events';
  static const String categoriesCacheKey = 'cached_categories';
  static const Color primaryBeige = Color(0xFFFAF7F4);
  static const Color primaryRed = Color(0xFF9B111E); // Senior Engineer Update: 9B111E
  static const Color primaryBlack = Color(0xFF1A1A1A); // Updated to near-black
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color secondaryGray = Color(0xFF757575);

  static const String ticketRevealRoute = '/ticket-reveal';
  static const String myTicketsRoute = '/my-tickets';
}

class AppStrings {
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
  static const String notificationsTitle = 'Notifications';
  static const String passwordMismatch = 'Passwords do not match';
  static const String acceptTermsError = 'You must accept terms and privacy policy';
  static const String phoneValidation = 'Please enter a valid Kenyan phone number';
}

class ApiConstants {
  static const String baseUrl = 'http://192.168.100.6:8000';
  static const int timeout = 30;
  static String fixMediaUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '$base$path';
  }

  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.startsWith('data:image')) return true;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.hasScheme && uri.hasAuthority;
  }
}
