import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const background = Color(0xFF0B0612);
  static const backgroundEnd = Color(0xFF190F2A);
  static const surface = Color(0xFF24173D);
  static const surfaceRaised = Color(0xFF30204D);
  static const accent = Color(0xFFA855F7);
  static const accentLight = Color(0xFFC084FC);
  static const gold = Color(0xFFF59E0B);
  static const mint = Color(0xFF73E2C3);
  static const text = Color(0xFFF4EFFA);
  static const muted = Color(0xFF9D91AA);
  static const outline = Color(0xFF3A2C49);
}

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentLight,
        secondary: AppColors.mint,
        surface: AppColors.surface,
        error: Color(0xFFFF7185),
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        hintStyle: const TextStyle(color: AppColors.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.accentLight, width: 1.4),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.accentLight,
        inactiveTrackColor: AppColors.outline,
        thumbColor: AppColors.text,
        overlayColor: AppColors.accent.withValues(alpha: 0.2),
      ),
    );
  }
}
