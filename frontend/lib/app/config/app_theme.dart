import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const Color primaryColor = Color(0xFF00CED1);
    const Color secondaryColor = Color(0xFFFFA500);
    const Color backgroundColor = Color(0xFF121212);
    const Color surfaceColor = Color(0xFF1E1E1E);
    const Color onPrimaryColor = Colors.white;
    const Color onSecondaryColor = Colors.black;
    const Color onBackgroundColor = Colors.white;
    const Color errorColor = Color(0xFFCF6679);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      background: backgroundColor,
      surface: surfaceColor,
      primary: primaryColor,
      onPrimary: onPrimaryColor,
      secondary: secondaryColor,
      onSecondary: onSecondaryColor,
      onBackground: onBackgroundColor,
      error: errorColor,
      onError: Colors.black,
      surfaceContainer: const Color(0xFF2C2C2C),
      surfaceContainerHighest: const Color(0xFF3A3A3A),
      onSurface: onBackgroundColor,
      onSurfaceVariant: Colors.white.withOpacity(0.7),
      outlineVariant: Colors.white.withOpacity(0.3),
    );

    final textTheme = TextTheme(
      displayMedium: TextStyle(
          color: onBackgroundColor,
          fontWeight: FontWeight.w900,
          fontSize: 36,
          letterSpacing: 1.5),
      headlineLarge:
          TextStyle(color: onBackgroundColor, fontWeight: FontWeight.bold, fontSize: 32),
      headlineMedium:
          TextStyle(color: onBackgroundColor, fontWeight: FontWeight.bold, fontSize: 28),
      headlineSmall:
          TextStyle(color: onBackgroundColor, fontWeight: FontWeight.bold, fontSize: 24),
      titleLarge:
          TextStyle(color: onBackgroundColor, fontWeight: FontWeight.bold, fontSize: 22),
      titleMedium:
          TextStyle(color: onBackgroundColor, fontWeight: FontWeight.bold, fontSize: 16),
      titleSmall:
          TextStyle(color: onBackgroundColor, fontWeight: FontWeight.w500, fontSize: 14),
      bodyLarge: TextStyle(color: onBackgroundColor, fontSize: 16, height: 1.5),
      bodyMedium:
          TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, height: 1.5),
      bodySmall:
          TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, height: 1.5),
      labelLarge: TextStyle(
          color: onPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.0),
      labelMedium:
          TextStyle(color: onBackgroundColor, fontWeight: FontWeight.bold, fontSize: 12),
      labelSmall: TextStyle(
          color: onBackgroundColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: onBackgroundColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(color: primaryColor),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: textTheme.bodyMedium,
      ),
    );
  }

  static ThemeData get darkTheme {
    return lightTheme;
  }
}
