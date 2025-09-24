import 'package:flutter/material.dart';

// Light & Dark Outlined Buttton Themes
class TOutlinedButtonTheme {
  TOutlinedButtonTheme._();// private constructor เพื่อป้องกันการสร้าง instance ของคลาสนี้

  // Light Theme
  static final LightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0, // ไม่ให้ปุ่มมีเงา
      foregroundColor: Colors.black, // สีตัวอักษรบนปุ่มเป็นสีดำ
      side: const BorderSide(color: Colors.blue), // ขอบของปุ่มเป็นสีน้ำเงิน
      textStyle: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600), // ขนาดฟอนต์ 16px, สีดำ, ตัวหนา
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // padding ด้านในปุ่ม (บน-ล่าง 16px, ข้าง 20px)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), // มุมของปุ่มเป็นโค้งมน 14px
    ),
  );
//  Dark Theme
static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white, // สีตัวอักษรบนปุ่มเป็นสีขาว
    side: const BorderSide(color: Colors.blueAccent), // ขอบของปุ่มเป็นสีน้ำเงินเข้ม
    textStyle: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600), // ขนาดฟอนต์ 16px, สีขาว, ตัวหนา
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // padding ด้านในปุ่ม (บน-ล่าง 16px, ข้าง 20px)
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), // มุมของปุ่มเป็นโค้งมน 14px
   ),
 );
}