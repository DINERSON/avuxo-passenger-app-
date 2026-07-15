import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color neonGreen = Color(0xFF00FF8F);
  static const Color neonBlue = neonGreen;

  static const Color background = Color(0xFF0D1117);
  static const Color card = Color(0xFF1A1F2B);
  static const Color card2 = Color(0xFF111827);
  static const Color border = Color(0xFF2A2F3A);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF8B949E);
  static const Color success = Color(0xFF00FF8F);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: neonGreen,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      dividerColor: border,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: neonGreen,
        secondary: neonGreen,
        surface: card,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: white,
        error: Colors.redAccent,
        onError: white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w800,
        ),
        displaySmall: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: GoogleFonts.poppins(
          color: grey,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: GoogleFonts.poppins(
          color: white,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.poppins(
          color: grey,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(
          color: white,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: neonGreen.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: border,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.poppins(
          color: Colors.white38,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: neonGreen,
        suffixIconColor: Colors.white54,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: neonGreen,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.4,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(
            double.infinity,
            58,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: white,
          side: const BorderSide(
            color: border,
          ),
          minimumSize: const Size(
            double.infinity,
            56,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: neonGreen,
      ),
    );
  }
}