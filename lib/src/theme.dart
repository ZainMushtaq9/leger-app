import 'package:flutter/material.dart';

const Color kKhataGreen = Color(0xFF1F6F5F);
const Color kKhataAmber = Color(0xFFF1B94F);
const Color kKhataDanger = Color(0xFFD85848);
const Color kKhataSuccess = Color(0xFF2F8E63);
const Color kKhataPaper = Color(0xFFFFF7EA);
const Color kKhataInk = Color(0xFF1F2A2E);
const String kBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

ThemeData buildHisabRakhoTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final baseScheme = ColorScheme.fromSeed(
    seedColor: kKhataGreen,
    brightness: brightness,
  );

  final surface = isDark ? const Color(0xFF121A1D) : Colors.white;
  final scaffold = isDark ? const Color(0xFF0A1012) : kKhataPaper;
  final onSurface = isDark ? const Color(0xFFF2F5F4) : kKhataInk;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: baseScheme.copyWith(
      primary: kKhataGreen,
      secondary: kKhataAmber,
      error: kKhataDanger,
      surface: surface,
      onSurface: onSurface,
    ),
    scaffoldBackgroundColor: scaffold,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.35, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: onSurface),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : kKhataGreen.withValues(alpha: 0.08),
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF182126) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : kKhataGreen.withValues(alpha: 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : kKhataGreen.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: kKhataGreen, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        backgroundColor: kKhataGreen,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        foregroundColor: kKhataGreen,
        side: const BorderSide(color: kKhataGreen, width: 1.3),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: surface,
      indicatorColor: kKhataAmber.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF203038) : kKhataInk,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
