import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class AppTypography {
  static TextStyle displayLarge = GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle displayMedium = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static TextStyle screenTitle = GoogleFonts.dmSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle labelMedium = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle buttonText = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: Colors.white,
  );

  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
}
