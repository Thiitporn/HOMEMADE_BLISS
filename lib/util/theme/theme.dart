import 'package:flutter/material.dart';

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
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryColor, // สีหลัก
      foregroundColor: Colors.white,  // สีตัวอักษร/ไอคอน
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: kDarkColor),
      bodyLarge: TextStyle(color: kDarkColor),
      titleLarge: TextStyle(color: kPrimaryColor),
    ),
    // เพิ่มเติมได้ตามต้องการ
  );

  // -----------------------------
  // Dark Theme (โหมดมืด)
  // -----------------------------
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: kDarkColor,
    scaffoldBackgroundColor: kDarkColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkColor,    // สีเข้ม
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: kBackgroundColor),
      bodyLarge: TextStyle(color: kBackgroundColor),
      titleLarge: TextStyle(color: kSecondaryColor),
    ),
    // เพิ่มเติมได้ตามต้องการ
  );
}
