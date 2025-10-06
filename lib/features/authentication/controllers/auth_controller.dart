// Auth Controller (ควบคุม logic การล็อกอิน/สมัครสมาชิก)
// EN: Controller for authentication logic

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isLoggedIn = true;
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message; // error message
    }
  }

  // Signup
  Future<String?> signup(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _isLoggedIn = true;
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message; // error message
    }
  }

  void logout() async {
    await _auth.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }
}