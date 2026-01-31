import 'package:flutter/material.dart';

class AppTheme {
  // COLORS
  static const Color primary = Color(0xFF374151);
  static const Color background = Color(0xFFF9FAFB);
  static const Color card = Color(0xFFE5E7EB);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusBorrowed = Color(0xFF374151);
  static const Color statusReturned = Color(0xFF16A34A);
  static const Color statusLate = Color(0xFFEF4444);
  static const Color statusConfirm = Color(0xFF2563EB);

  static double _textScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width <= 320) return 0.85;
    if (width <= 420) return 1.0;
    return 1.15;
  }

  static TextTheme textTheme(BuildContext context) {
    final scale = _textScale(context);

    return TextTheme(
      headlineLarge: TextStyle(fontSize: 30 * scale, fontWeight: FontWeight.bold, color: textPrimary),
      headlineMedium: TextStyle(fontSize: 24 * scale, fontWeight: FontWeight.bold, color: textPrimary),
      headlineSmall: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 18 * scale, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 16 * scale, color: textPrimary),
      bodySmall: TextStyle(fontSize: 14 * scale, color: textPrimary),
    );
  }

  static ThemeData lightTheme(BuildContext context) {
    final scheme = const ColorScheme.light(
      primary: primary,
      secondary: primary,
      surface: card,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      error: statusLate,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: card, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        // Kalau kamu mau error muncul, jangan set height 0
        errorStyle: const TextStyle(fontSize: 12),
      ),

      iconTheme: IconThemeData(
        size: 24,
        color: scheme.primary,
      ),

      textTheme: textTheme(context),
    );
  }
}
