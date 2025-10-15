import 'package:flutter/material.dart';

class InAppNotification {
  static void show(BuildContext context, String message, {Color? color, Duration? duration}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.green,
      duration: duration ?? const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
