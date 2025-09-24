
import 'package:flutter/material.dart';

class TColors {
  TColors._();

 
 // App Basic Colors
  static const Color primary = Color(0xFF4b68ff);
  static const Color secondary = Color(0xFF6C757D);
  static const Color accent = Color(0xFFF5F5F5);
   
   // Gradients Colors
   static const Gradient linearGradient = LinearGradient(
    begin: Alignment(0.0, 0.0),
    end: Alignment(0.707, -0.707),
    colors: [
      Color(0xffff9a9e), 
      Color(0xfffad0c4), 
      Color(0xfffad0c4),
    ],
  );

  // Text Colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textWhite = Color(0xFF333333);

  // Background Colors
  static const Color light = Color(0xFFF6F6F6);
  static const Color dark = Color(0xFF121212);
  static const Color primaryBackground = Color(0xFFFFFFFF);

  static const Color lightContainer = Color(0xFFE0E0E0);
  static final Color whiteWithOpacity = white.withOpacity(0.1);

  // Button Colors (สีของปุ่มต่างๆ)
  static const Color buttonPrimary = Color(0xFF4b68ff); // สีหลักของปุ่ม
  static const Color buttonSecondary = Color(0xFF6C757D); // สีรองของปุ่ม
  static const Color buttonDisabled = Color(
    0xFFC4C4C4,
  ); // สีของปุ่มเมื่อถูกปิดใช้งาน

  // Border Colors (สีของขอบ)
  static const Color borderPrimary = Color(0xFFD9D9D9); // ขอบสีหลัก
  static const Color borderSecondary = Color(0xFFE6E6E6); // ขอบสีรอง

  // Error and Validation Colors (สีสำหรับการแสดงผลข้อผิดพลาดและสถานะต่างๆ)
  static const Color error = Color(0xFFD32F2F); // สีของข้อความผิดพลาด (แดง)
  static const Color success = Color(0xFF388E3C); // สีของสถานะสำเร็จ (เขียว)
  static const Color warning = Color(0xFFFF5722); // สีของคำเตือน (ส้ม)
  static const Color info = Color(0xFF1976D2); // สีของข้อมูล (น้ำเงิน)

  /// Neutral Shades (เฉดสีที่เป็นกลาง)
  static const Color black = Color(0xFF232323); // สีดำ
  static const Color darkerGrey = Color(0xFF4F4F4F); // สีเทาเข้ม
  static const Color darkGrey = Color(0xFF939393); // สีเทาเข้มมาก
  static const Color grey = Color(0xFFEEEEEE); // สีเทาอ่อน
  static const Color lightGrey = Color(0xFFF5F5F5); // สีเทาอ่อนมาก
  static const Color white = Color(0xFFFFFFFF); // สีขาว
}