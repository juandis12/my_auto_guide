import 'package:flutter/material.dart';

class BrandTheme {
  final Color primaryColor;
  final Color accentColor;
  final LinearGradient gradient;

  const BrandTheme({
    required this.primaryColor,
    required this.accentColor,
    required this.gradient,
  });

  static const BrandTheme defaultTheme = BrandTheme(
    primaryColor: Color(0xFF2563EB),
    accentColor: Color(0xFF60A5FA),
    gradient: LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static final Map<String, BrandTheme> _themes = {
    'YAMAHA': const BrandTheme(
      primaryColor: Color(0xFF003087),
      accentColor: Color(0xFF0056D2),
      gradient: LinearGradient(
        colors: [Color(0xFF003087), Color(0xFF0056D2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    'SUZUKI': const BrandTheme(
      primaryColor: Color(0xFFCF122D),
      accentColor: Color(0xFFEC1C24),
      gradient: LinearGradient(
        colors: [Color(0xFFCF122D), Color(0xFFEC1C24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    'BMW': const BrandTheme(
      primaryColor: Color(0xFF0066B2),
      accentColor: Color(0xFF898E8C),
      gradient: LinearGradient(
        colors: [Color(0xFF0066B2), Color(0xFF009CDE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    'KAWASAKI': const BrandTheme(
      primaryColor: Color(0xFF66FF00),
      accentColor: Color(0xFF1E1E1E),
      gradient: LinearGradient(
        colors: [Color(0xFF66FF00), Color(0xFF4CBB17)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    'HONDA': const BrandTheme(
      primaryColor: Color(0xFFE4002B),
      accentColor: Color(0xFFFFFFFF),
      gradient: LinearGradient(
        colors: [Color(0xFFE4002B), Color(0xFFB00020)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    'DUCATI': const BrandTheme(
      primaryColor: Color(0xFFCC0000),
      accentColor: Color(0xFF1E1E1E),
      gradient: LinearGradient(
        colors: [Color(0xFFCC0000), Color(0xFF8B0000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    'KTM': const BrandTheme(
      primaryColor: Color(0xFFFF6600),
      accentColor: Color(0xFF1E1E1E),
      gradient: LinearGradient(
        colors: [Color(0xFFFF6600), Color(0xFFE65C00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    'BAJAJ': const BrandTheme(
      primaryColor: Color(0xFF0055A5),
      accentColor: Color(0xFFFFFFFF),
      gradient: LinearGradient(
        colors: [Color(0xFF0055A5), Color(0xFF003D7A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  };

  static BrandTheme getTheme(String? brand) {
    if (brand == null) return defaultTheme;
    final normalized = brand.toUpperCase();
    return _themes[normalized] ?? defaultTheme;
  }
}
