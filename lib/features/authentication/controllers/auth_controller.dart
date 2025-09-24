// Auth Controller (ควบคุม logic การล็อกอิน/สมัครสมาชิก)
// EN: Controller for authentication logic

import 'package:flutter/material.dart';

class AuthController with ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void login(String email, String password) {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}