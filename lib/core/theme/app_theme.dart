import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Azul eléctrico
  static const Color bgDark = Color(0xFF040F23);
  static const Color bgCard = Color(0xFF0D1E3A);
  static const Color bgCard2 = Color(0xFF143054);
  static const Color border = Color(0xFF1B3A5F);
  static const Color accent = Color(0xFF007AFF); // azul eléctrico principal
  static const Color accent2 = Color(0xFF00C2FF); // cian eléctrico
  static const Color accent3 = Color(0xFF00E5FF);
  static const Color success = Color(0xFF00D68F);
  static const Color warning = Color(0xFFFFB800);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8AA0C2);
  static const Color textMuted = Color(0xFF5C7494);

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      primary: accent,
      secondary: accent2,
      tertiary: accent3,
      surface: bgDark,
      error: accent,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgDark,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1.5, color: textPrimary),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF040F23), Color(0xFF0A1E3C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00D68F), Color(0xFF00B8A9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
