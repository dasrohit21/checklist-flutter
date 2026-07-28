import 'package:flutter/material.dart';

enum AppThemeMode { dark, light, oledBlack, blue }

class AppTheme {
  static AppThemeMode activeTheme = AppThemeMode.dark;

  static Color get bg {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFFF8FAFC);
      case AppThemeMode.oledBlack:
        return const Color(0xFF000000);
      case AppThemeMode.blue:
        return const Color(0xFF0B132B);
      case AppThemeMode.dark:
        return const Color(0xFF0F172A);
    }
  }

  static Color get surface {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFFFFFFFF);
      case AppThemeMode.oledBlack:
        return const Color(0xFF0A0A0A);
      case AppThemeMode.blue:
        return const Color(0xFF1C2541);
      case AppThemeMode.dark:
        return const Color(0xFF15233C);
    }
  }

  static Color get surfaceStrong {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFFE2E8F0);
      case AppThemeMode.oledBlack:
        return const Color(0xFF1A1A1A);
      case AppThemeMode.blue:
        return const Color(0xFF3A506B);
      case AppThemeMode.dark:
        return const Color(0xFF1E3456);
    }
  }

  static Color get text {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFF0F172A);
      case AppThemeMode.oledBlack:
        return const Color(0xFFF3F4F6);
      case AppThemeMode.blue:
        return const Color(0xFFE0E1DD);
      case AppThemeMode.dark:
        return const Color(0xFFE2E8F0);
    }
  }

  static Color get textMuted {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFF64748B);
      case AppThemeMode.oledBlack:
        return const Color(0xFF9CA3AF);
      case AppThemeMode.blue:
        return const Color(0xFF8D99AE);
      case AppThemeMode.dark:
        return const Color(0xFF94A3B8);
    }
  }

  static Color get accent {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFF0284C7);
      case AppThemeMode.oledBlack:
        return const Color(0xFF38BDF8);
      case AppThemeMode.blue:
        return const Color(0xFF48CAE4);
      case AppThemeMode.dark:
        return const Color(0xFF38BDF8);
    }
  }

  static Color get success {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFF16A34A);
      case AppThemeMode.oledBlack:
        return const Color(0xFF4ADE80);
      case AppThemeMode.blue:
        return const Color(0xFF06D6A0);
      case AppThemeMode.dark:
        return const Color(0xFF4ADE80);
    }
  }

  static Color get warning {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFFD97706);
      case AppThemeMode.oledBlack:
        return const Color(0xFFFBBF24);
      case AppThemeMode.blue:
        return const Color(0xFFFFB703);
      case AppThemeMode.dark:
        return const Color(0xFFFBBF24);
    }
  }

  static Color get danger {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFFDC2626);
      case AppThemeMode.oledBlack:
        return const Color(0xFFFB7185);
      case AppThemeMode.blue:
        return const Color(0xFFEF233C);
      case AppThemeMode.dark:
        return const Color(0xFFFB7185);
    }
  }

  static Color get feature {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFF7C3AED);
      case AppThemeMode.oledBlack:
        return const Color(0xFFA78BFA);
      case AppThemeMode.blue:
        return const Color(0xFF7209B7);
      case AppThemeMode.dark:
        return const Color(0xFFA78BFA);
    }
  }

  static Color get border {
    switch (activeTheme) {
      case AppThemeMode.light:
        return const Color(0xFFCBD5E1);
      case AppThemeMode.oledBlack:
        return const Color(0xFF262626);
      case AppThemeMode.blue:
        return const Color(0xFF1B263B);
      case AppThemeMode.dark:
        return const Color(0xFF47597D);
    }
  }

  static ThemeData buildTheme() {
    final isLight = activeTheme == AppThemeMode.light;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: bg,
      brightness: isLight ? Brightness.light : Brightness.dark,
      colorScheme: ColorScheme(
        brightness: isLight ? Brightness.light : Brightness.dark,
        primary: accent,
        onPrimary: isLight ? Colors.white : const Color(0xFF0F172A),
        secondary: feature,
        onSecondary: Colors.white,
        error: danger,
        onError: Colors.white,
        surface: surface,
        onSurface: text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0x0F172A0F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent),
        ),
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7)),

      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: text),
        bodyLarge: TextStyle(color: text),
        titleMedium: TextStyle(color: text),
        titleLarge: TextStyle(color: text),
      ),
    );
  }

  // ── Spacing System ────────────────────────────────────────────────────────
  static const double sp8  = 8;
  static const double sp10 = 10;
  static const double sp12 = 12;
  static const double sp14 = 14;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp32 = 32;

  // ── Typography Scale ──────────────────────────────────────────────────────
  static const TextStyle displayStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static const TextStyle headingStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.1,
  );
  static const TextStyle buttonStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  static const TextStyle labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  );

  // ── Semantic Color Aliases ─────────────────────────────────────────────────
  /// Alias for accent — the primary interactive blue.
  static Color get primary => accent;

  /// Purple — used for learning/insights sections.
  static Color get learning => feature;

  static Color typeColor(String type) {
    switch (type) {
      case 'bug':
        return danger;
      case 'feature':
        return feature;
      case 'study':
        return success;
      default:
        return accent;
    }
  }
}
