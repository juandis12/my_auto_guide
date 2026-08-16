import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apple HIG Design System for MY AUTO GUIDE
/// Theme: Medianoche Dinámico (Dynamic Midnight)
/// Glassmorphism: Heavy Blur (sigma: 20)
/// Typography: Outfit (SF Pro Inspired)
class AppAppleTheme {
  // Brand Palette - Dynamic Midnight
  static const Color midnightBackground = Color(0xFF080C14);
  static const Color midnightSurface = Color(0xFF0F172A);
  static const Color midnightSurfaceElevated = Color(0xFF1E293B);
  
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color electricBlueLight = Color(0xFF3B82F6);
  static const Color electricCyan = Color(0xFF38BDF8);

  // Glass Colors
  static Color glassBackground = const Color(0xFF0F172A).withValues(alpha: 0.75);
  static Color glassBackgroundLight = const Color(0xFFFFFFFF).withValues(alpha: 0.85);
  static Color glassBorder = const Color(0xFF38BDF8).withValues(alpha: 0.18);
  static Color glassBorderLight = const Color(0xFF000000).withValues(alpha: 0.08);

  // Glassmorphism Blur Intensity
  static const double glassBlurSigma = 20.0;

  // Cupertino Spring Animations Physics
  static const Duration springDuration = Duration(milliseconds: 350);
  static const Curve springCurve = Curves.easeOutCubic;

  /// Dark Theme Definition (Apple HIG Dynamic Midnight)
  static ThemeData get darkTheme {
    final baseDark = ThemeData.dark();
    final outfitText = GoogleFonts.outfitTextTheme(baseDark.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: midnightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: electricBlue,
        brightness: Brightness.dark,
        primary: electricBlue,
        secondary: electricCyan,
        surface: midnightSurface,
        onSurface: Colors.white,
      ),
      textTheme: outfitText.apply(
        bodyColor: Colors.white.withValues(alpha: 0.92),
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: glassBorder,
            width: 1.2,
          ),
        ),
        color: glassBackground,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: midnightSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: glassBorder, width: 1.0),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Light Theme Definition
  static ThemeData get lightTheme {
    final baseLight = ThemeData.light();
    final outfitText = GoogleFonts.outfitTextTheme(baseLight.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: electricBlue,
        brightness: Brightness.light,
        primary: electricBlue,
        secondary: electricBlueLight,
        surface: const Color(0xFFF1F5F9),
        onSurface: Colors.black87,
      ),
      textTheme: outfitText.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: glassBorderLight,
            width: 1.0,
          ),
        ),
        color: glassBackgroundLight,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
