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

  // 👉 Fungsi untuk bikin scale berdasarkan ukuran layar
  static double _textScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Jika layar kecil -> scale kecil
    if (width <= 320) return 0.85;

    // Layar normal (HP kebanyakan)
    if (width <= 420) return 1.0;

    // Tablet / layar besar
    return 1.15;
  }

  // 👉 TextTheme yang otomatis mengikuti scale
  static TextTheme textTheme(BuildContext context) {
    final scale = _textScale(context);

    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30 * scale,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24 * scale,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20 * scale,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 18 * scale,  // diubah jadi lebih besar
        color: textPrimary,    // gunakan textPrimary biar jelas
      ),
      bodyMedium: TextStyle(
        fontSize: 16 * scale,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 14 * scale,
        color: textSecondary,
      ),
    );
  }

  // 👉 ThemeData yang menggunakan textTheme(context)
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,

      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        background: background,
        surface: card,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        error: statusLate,
      ),

      scaffoldBackgroundColor: background,

      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: card),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),

        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: statusLate),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: statusLate, width: 1.5),
        ),

        errorStyle: const TextStyle(height: 0, fontSize: 0),
      ),

      // 👉 Tambahkan divider agar garis terlihat
      dividerTheme: const DividerThemeData(
        thickness: 1.2,
        color: Colors.grey,
      ),

      iconTheme: const IconThemeData(
        size: 24,
        color: primary,
      ),

      textTheme: textTheme(context),
    );
  }
}
