import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Space-Dark Palette
  static const Color midnightBlue = Color(0xFF0B0F19);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color ecoGreen = Color(0xFF00FF94);
  static const Color alertRed = Color(0xFFFF2A6D);
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% opacity

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: midnightBlue,
      primaryColor: ecoGreen,
      colorScheme: const ColorScheme.dark(
        primary: ecoGreen,
        secondary: neonCyan,
        surface: midnightBlue,
        error: alertRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      useMaterial3: true,
    );
  }
}
