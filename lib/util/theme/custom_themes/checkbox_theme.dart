import 'package:flutter/material.dart';

// คลาสเก็บธีมของ Checkbox แยกเป็น Light และ Dark
class TCheckboxTheme {
  TCheckboxTheme._(); 
  // ใช้ private constructor (_) เพื่อป้องกันการสร้าง instance
  // คลาสนี้ทำมาเก็บ static theme เท่านั้น

  /// -------------------------------
  /// Light Theme (โหมดสว่าง)
  /// -------------------------------
  static CheckboxThemeData lightCheckboxTheme = CheckboxThemeData(
    // กำหนดรูปร่างของ checkbox เป็นสี่เหลี่ยมมุมโค้งมน radius 4
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),

    // สีของ "เครื่องหมายถูก" (check mark)
    checkColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        // ถ้า checkbox ถูกเลือก → เครื่องหมายถูกเป็นสีขาว
        return Colors.white;
      } else {
        // ถ้าไม่ถูกเลือก → ไม่มีเครื่องหมาย (สีดำ)
        return Colors.black;
      }
    }),

    // สีพื้นหลังของกล่อง checkbox
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        // ถ้าถูกเลือก → กล่องพื้นหลังสีน้ำเงิน
        return Colors.blue;
      } else {
        // ถ้าไม่ถูกเลือก → กล่องโปร่งใส
        return Colors.transparent;
      }
    }),
  );

  /// -------------------------------
  /// Dark Theme (โหมดมืด)
  /// -------------------------------
  static CheckboxThemeData darkCheckboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),

    checkColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        // ถ้าถูกเลือก → เครื่องหมายถูกเป็นสีขาว
        return Colors.white;
      } else {
        // ถ้าไม่ถูกเลือก → สีดำ
        return Colors.black;
      }
    }),

    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        // ถ้าถูกเลือก → กล่อง checkbox เป็นสีน้ำเงิน
        return Colors.blue;
      } else {
        // ถ้าไม่ถูกเลือก → โปร่งใส
        return Colors.transparent;
      }
    }),
  );
}
