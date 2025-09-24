import 'package:flutter/material.dart';

/// คลาสเก็บธีมของ Chip แยกเป็น Light และ Dark
class TChipTheme {
  TChipTheme._(); 
  // ใช้ private constructor (_) เพื่อป้องกันการสร้าง instance
  // คลาสนี้จะเก็บเฉพาะค่า static เท่านั้น

  /// -------------------------------
  /// Light Theme (โหมดสว่าง)
  /// -------------------------------
  static ChipThemeData lightChipTheme = ChipThemeData(
    disabledColor: Colors.grey.withOpacity(0.4), // สี chip เมื่อถูกปิดการใช้งาน (disabled)
    labelStyle: const TextStyle(color: Colors.black), // สีตัวอักษรบน chip
    selectedColor: Colors.blue, // สีพื้นหลังของ chip เมื่อถูกเลือก
    padding: const EdgeInsets.symmetric(
      horizontal: 12.0,
      vertical: 12.0,
    ), // padding ด้านในของ chip
    checkmarkColor: Colors.white, // สีของ checkmark (✔) ตอน chip ถูกเลือก
  );

  /// -------------------------------
  /// Dark Theme (โหมดมืด)
  /// -------------------------------
  static const ChipThemeData darkChipTheme = ChipThemeData(
    disabledColor: Colors.grey, // สี chip ตอน disabled
    labelStyle: TextStyle(color: Colors.white), // ตัวอักษรเป็นสีขาว
    selectedColor: Colors.blue, // สี chip ตอนถูกเลือกเป็นสีน้ำเงิน
    padding: EdgeInsets.symmetric(
      horizontal: 12.0,
      vertical: 12.0,
    ), // ระยะห่างด้านใน
    checkmarkColor: Colors.white, // สีของเครื่องหมาย ✔ ตอนเลือกแล้ว
  );
}
