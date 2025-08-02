import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF6C63FF); // Purple
  static const Color accentColor = Color(0xFFFFB300); // Amber/Gold
  static const Color backgroundColor = Colors.white;
  static const Color headingColor = Colors.black87;
  static const Color descriptionColor = Colors.grey;
  static const Color lightOrange = Color(0xFFFFE0B2);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1F1F1F);
  static const Color darkText = Colors.white70;

  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: headingColor),
      bodyMedium: const TextStyle(fontSize: 16, color: Colors.black87),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: accentColor,
    ),
  );

  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText),
      bodyMedium: const TextStyle(fontSize: 16, color: Colors.white70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
    ),
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
      secondary: accentColor,
    ),
  );
}
