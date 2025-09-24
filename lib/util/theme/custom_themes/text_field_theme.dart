import 'package:flutter/material.dart';

/// ธีมของ TextFormField / TextField
class TTextFormFieldTheme {
  TTextFormFieldTheme._(); // ใช้ private constructor เพื่อป้องกันการสร้าง instance

  /// -------------------------------
  /// Light InputDecorationTheme (สำหรับโหมดสว่าง)
  /// -------------------------------
  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3, // กำหนดจำนวนบรรทัดที่ข้อความ error แสดงได้สูงสุด
    prefixIconColor: Colors.grey, // สีของ icon ที่อยู่ข้างหน้า input
    suffixIconColor: Colors.grey, // สีของ icon ที่อยู่ข้างหลัง input
    // กำหนดขนาดและความสูงของ TextFormField
    constraints: const BoxConstraints.expand(height: 14.0),

    // กำหนดสไตล์ของ label (คำบรรยายที่อยู่ในช่องกรอกข้อมูล)
    labelStyle: const TextStyle().copyWith(
      fontSize: 14, // ขนาดตัวอักษรของ label
      color: Colors.black, // สีของ label
    ),

    // กำหนดสไตล์ของ hint (คำบอกเล่าเมื่อช่องกรอกข้อมูลว่าง)
    hintStyle: const TextStyle().copyWith(
      fontSize: 14,
      color: Colors.black, // สีของ hint text
    ),

    // กำหนดสไตล์ของ error text
    errorStyle: const TextStyle().copyWith(
      fontSize: 13,
      fontWeight: FontWeight.normal, // ความหนาของฟอนต์
    ),

    // กำหนดสไตล์ของ floating label (เมื่อกรอกข้อมูลแล้ว label จะยกขึ้น)
    floatingLabelStyle: const TextStyle().copyWith(
      color: Colors.black.withOpacity(0.8), // สีของ floating label
    ),

    // กำหนดขอบของช่องกรอกข้อมูลที่เปิดใช้งาน (enabled)
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14), // มุมของขอบ
      borderSide: const BorderSide(width: 1, color: Colors.grey), // ขอบสีเทา
    ),

    // กำหนดขอบของช่องกรอกข้อมูลที่ได้รับการ focus
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        width: 1,
        color: Colors.black12,
      ), // ขอบสีดำอ่อน
    ),

    // กำหนดขอบของช่องกรอกข้อมูลเมื่อเกิดข้อผิดพลาด
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.red), // ขอบสีแดง
    ),

    // กำหนดขอบของช่องกรอกข้อมูลที่ focus และเกิดข้อผิดพลาด
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: Colors.orange), // ขอบสีส้ม
    ),
  );

  /// -------------------------------
  /// Dark InputDecorationTheme (สำหรับโหมดมืด)
  /// -------------------------------
  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 2, // โหมดมืดกำหนด error ให้แสดงได้สูงสุด 2 บรรทัด
    prefixIconColor: Colors.grey,
    suffixIconColor: Colors.grey,

    constraints: const BoxConstraints.expand(height: 14.0),

    labelStyle: const TextStyle().copyWith(
      fontSize: 14,
      color: Colors.white, // เปลี่ยนเป็นสีขาวในโหมดมืด
    ),

    hintStyle: const TextStyle().copyWith(
      fontSize: 14,
      color: Colors.white, // สีของ hint text ในโหมดมืด
    ),

    floatingLabelStyle: const TextStyle().copyWith(
      color: Colors.white.withOpacity(0.8), // สีของ floating label ในโหมดมืด
    ),

    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.grey),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.white),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.red),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: Colors.orange),
    ),
  );
}
