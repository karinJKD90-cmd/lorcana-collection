import 'package:flutter/material.dart';

class LorcanaTheme {
  static const Color gold = Color(0xFFC9A961);
  static const Color background = Color(0xFF0A0614);
  static const Color surface = Color(0xFF130D22);
  static const Color textPrimary = Color(0xFFF4E4A1);
  static const Color textMuted = Color(0xFF8A7A4A);
  static const Color borderColor = Color(0xFF2A1F4A);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          surface: surface,
          onPrimary: background,
          onSurface: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: gold,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
            color: gold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary, fontFamily: 'Georgia'),
          bodyMedium: TextStyle(color: textPrimary),
          labelSmall: TextStyle(color: textMuted, fontSize: 11),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: gold),
          ),
          labelStyle: const TextStyle(color: textMuted),
        ),
        dividerColor: borderColor,
        cardColor: surface,
      );
}
