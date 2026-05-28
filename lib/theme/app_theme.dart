import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LightTheme {
  // Brand Colors
  static const primary = Color(0xFF00D4FF);     // Cyan-electric
  static const primary2 = Color(0xFF7B2FFF);    // Deep violet
  static const accent = Color(0xFF00FF94);       // Neon green
  static const danger = Color(0xFFFF3B5C);
  static const warning = Color(0xFFFFB830);

  // Light Mode
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F7FA);
  static const border = Color(0xFFE8ECF2);
  static const textPrimary = Color(0xFF0D1117);
  static const textSecondary = Color(0xFF6B7589);
  static const textHint = Color(0xFFADB5C7);

  // Dark Mode
  static const darkBg = Color(0xFF0A0C10);
  static const darkSurface = Color(0xFF13161E);
  static const darkSurface2 = Color(0xFF1C2030);
  static const darkBorder = Color(0xFF252A38);
  static const darkText = Color(0xFFEEF0F6);
  static const darkTextSec = Color(0xFF8892AA);

  static TextTheme get textTheme => GoogleFonts.spaceGroteskTextTheme();

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    textTheme: textTheme,
    scaffoldBackgroundColor: surfaceAlt,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    ),
    scaffoldBackgroundColor: darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

// Gradient Definitions
class LightGradients {
  static const brand = LinearGradient(
    colors: [LightTheme.primary, LightTheme.primary2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGlow = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF00FF94)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkCard = LinearGradient(
    colors: [Color(0xFF1C2030), Color(0xFF13161E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const homeGradient = LinearGradient(
    colors: [Color(0xFF0A0C10), Color(0xFF0D1520)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
