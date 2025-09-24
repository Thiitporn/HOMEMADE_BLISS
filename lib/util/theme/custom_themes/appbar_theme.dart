import 'package:flutter/material.dart';

// ประกาศเฉพาะ AppBarTheme ที่นี่
class TAppBarTheme {
  static const AppBarTheme lightAppBarTheme = AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  );

  static const AppBarTheme darkAppBarTheme = AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 0,
  );
}