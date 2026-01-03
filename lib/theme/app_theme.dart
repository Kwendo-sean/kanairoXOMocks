import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F1EA), // Warm beige
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF8B0000), // Deep red
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1A1A1A), // Near-black
        secondary: Color(0xFF8B7355), // Warm brown accent
        onSecondary: Colors.white,
        outline: Color(0xFFE0D7CC), // Light warm gray border
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F1EA),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF4A4A4A), // Muted text
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF6B6B6B), // Secondary text
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF8B0000),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B0000), // Deep red
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          side: const BorderSide(color: Color(0xFFE0D7CC)),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(0),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0D7CC),
        thickness: 1,
        space: 0,
      ),
    );
  }
}