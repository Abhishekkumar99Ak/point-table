import 'package:flutter/material.dart';

class AppTheme {
  // Pointcalc हेडर ग्रेडिएंट (मैरून से डार्क रेड)
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF9E3636),
      Color(0xFF6B1A1E),
    ],
  );

  // कलर्स (डिट्टो Pointcalc)
  static const Color scaffoldBg = Color(0xFFFBF6F6);
  static const Color cardBg = Colors.white;
  static const Color primaryMaroon = Color(0xFF7A2026);
  static const Color softPinkChip = Color(0xFFFDE8E8);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textMuted = Color(0xFF757575);
  static const Color deleteRed = Color(0xFFC93B3B);
  static const Color dividerLine = Color(0xFFEEEEEE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryMaroon,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryMaroon,
        primary: primaryMaroon,
        surface: cardBg,
      ),
      fontFamily: 'sans-serif',
    );
  }
}