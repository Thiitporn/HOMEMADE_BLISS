import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// กำหนดค่าสีหลัก
const Color kPrimaryColor = Color(0xFF74512D);
const Color kSecondaryColor = Color(0xFFAF8F6F);
const Color kBackgroundColor = Color(0xFFF8F4E1);
const Color kDarkColor = Color(0xFF543310);

class TAppTheme {
  TAppTheme._(); // private constructor ป้องกันการสร้าง instance

  // -----------------------------
  // Light Theme (โหมดสว่าง)
  // -----------------------------
  static final ThemeData lightTheme = _buildLightTheme();

  // -----------------------------
  // Dark Theme (โหมดมืด)
  // -----------------------------
  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final fontFamily = GoogleFonts.kanit().fontFamily;
    final base = ThemeData(
      fontFamily: fontFamily,
      brightness: Brightness.light,
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: kBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.kanit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: kPrimaryColor,
        secondary: kSecondaryColor,
        background: kBackgroundColor,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: kDarkColor,
        onSurface: kDarkColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.kanit(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
    return _applyKanitFont(
      base,
      bodyColor: kDarkColor,
      displayColor: kDarkColor,
      titleLargeColor: kPrimaryColor,
    );
  }

  static ThemeData _buildDarkTheme() {
    final fontFamily = GoogleFonts.kanit().fontFamily;
    final base = ThemeData(
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      primaryColor: kDarkColor,
      scaffoldBackgroundColor: kDarkColor,
      appBarTheme: AppBarTheme(
        backgroundColor: kDarkColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.kanit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: kDarkColor,
        secondary: kSecondaryColor,
        background: kDarkColor,
        surface: kPrimaryColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: kBackgroundColor,
        onSurface: kBackgroundColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.kanit(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
    return _applyKanitFont(
      base,
      bodyColor: kBackgroundColor,
      displayColor: kBackgroundColor,
      titleLargeColor: kSecondaryColor,
    );
  }

  static ThemeData _applyKanitFont(
    ThemeData base, {
    required Color bodyColor,
    required Color displayColor,
    Color? titleLargeColor,
  }) {
    final defaultTitleStyle = TextStyle(
      color: base.appBarTheme.foregroundColor ?? Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    );

    final textTheme = GoogleFonts.kanitTextTheme(base.textTheme).apply(
      bodyColor: bodyColor,
      displayColor: displayColor,
    );

    final adjustedTextTheme = textTheme.copyWith(
      titleLarge: titleLargeColor == null
          ? textTheme.titleLarge
          : textTheme.titleLarge?.copyWith(color: titleLargeColor) ??
              GoogleFonts.kanit(
                fontSize: textTheme.titleLarge?.fontSize ?? 22,
                fontWeight: textTheme.titleLarge?.fontWeight ?? FontWeight.w600,
                color: titleLargeColor,
              ),
    );

    return base.copyWith(
      textTheme: adjustedTextTheme,
      primaryTextTheme: GoogleFonts.kanitTextTheme(base.primaryTextTheme).apply(
        bodyColor: displayColor,
        displayColor: displayColor,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: GoogleFonts.kanit(
          textStyle: base.appBarTheme.titleTextStyle ?? defaultTitleStyle,
        ),
      ),
    );
  }
}
