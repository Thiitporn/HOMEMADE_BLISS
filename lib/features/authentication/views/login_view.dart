import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<String?> _login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      // แปลง error code เป็นข้อความที่ user เข้าใจง่าย
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for this email.';
        case 'wrong-password':
        case 'invalid-credential': // Firebase 11+ ใช้โค้ดนี้เมื่ออีเมล/รหัสผ่านไม่ถูกต้อง
          return 'Incorrect email or password. Please try again.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        default:
          return 'Login failed. Please check your email and password.';
      }
    } catch (_) {
      return 'Login failed. Please try again.';
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Reset Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your email address to receive a password reset link.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Email address',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your email';
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(v)) return 'Invalid email format';
                      return null;
                    },
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() {
                          sending = true;
                          errorMsg = null;
                        });
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: emailController.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset link sent! Please check your email.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          setState(() {
                            switch (e.code) {
                              case 'user-not-found':
                                errorMsg = 'No user found for this email.';
                                break;
                              case 'invalid-email':
                                errorMsg = 'Invalid email address.';
                                break;
                              default:
                                errorMsg = 'Failed to send reset email. Please try again.';
                            }
                            sending = false;
                          });
                        } catch (_) {
                          setState(() {
                            errorMsg = 'Failed to send reset email. Please try again.';
                            sending = false;
                          });
                        }
                      },
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ใช้โทนสีเดียวกับ signup
    final Color darkBrown = const Color(0xFF4E342E);
    final Color mediumBrown = const Color(0xFF8D6E63);
  // final Color lightBrown = const Color(0xFFD7CCC8); // not used here
    final Color cream = const Color(0xFFFAF3EF);
    final Color borderColor = const Color(0xFFE0CFC2);
    final Color buttonTextColor = Colors.white;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.cookie, color: mediumBrown, size: 22),
            const SizedBox(width: 6),
            Text(
              'Homemade Bliss',
              style: TextStyle(
                color: darkBrown,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: darkBrown),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            children: [
              const SizedBox(height: 18),
              Text(
                'Log in to your account',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: darkBrown,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your details',
                style: TextStyle(fontSize: 13, color: darkBrown.withOpacity(0.7)),
              ),
              const SizedBox(height: 28),
              // Email
              _InputFieldLogin(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'Email address',
                brown: darkBrown,
                borderColor: borderColor,
                fillColor: Colors.white,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your email';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v)) return 'Invalid email format';
                  return null;
                },
                dense: true,
              ),
              const SizedBox(height: 18),
              // Password
              _InputFieldLogin(
                controller: _pwdCtrl,
                label: 'Password',
                hint: 'Password',
                brown: darkBrown,
                borderColor: borderColor,
                fillColor: Colors.white,
                obscureText: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: mediumBrown, size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
                dense: true,
              ),
              const SizedBox(height: 10),
              // Login Button
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBrown,
                    foregroundColor: buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          setState(() => _isLoading = true);
                          String? error;
                          try {
                            error = await _login(
                              _emailCtrl.text.trim(),
                              _pwdCtrl.text.trim(),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }

                          if (!mounted) return;

                          if (error == null) {
                            // หลัง login สำเร็จ: สร้าง users/<uid> อัตโนมัติถ้ายังไม่มี
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                              if (!doc.exists) {
                                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                  'role': 'customer',
                                  'email': user.email,
                                  'phone': '',
                                  'displayName': user.displayName ?? '',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                              }
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Login successful')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red[300],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              // Forgot Password
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _showForgotPasswordDialog,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: darkBrown, // เพิ่ม contrast
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Sign Up link (secondary button style)
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mediumBrown,
                    side: BorderSide(color: mediumBrown, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignupView(),
                            ),
                          ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      // สีเข้มขึ้นเพื่อ contrast
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Already member? Login (ลบออกเพราะอยู่หน้า Login)
            ],
          ),
        ),
      ),
    );
  }
}

// ใช้ input field แบบเดียวกับ signup
class _InputFieldLogin extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Color brown;
  final Color borderColor;
  final Color fillColor;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool dense;

  const _InputFieldLogin({
    required this.controller,
    required this.label,
    required this.hint,
    required this.brown,
    required this.borderColor,
    required this.fillColor,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: brown, fontSize: 12)),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
            border: Border.all(color: borderColor, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              isDense: dense,
              contentPadding: dense
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: suffixIcon,
            ),
            style: TextStyle(fontSize: 12, color: brown),
          ),
        ),
      ],
    );
  }
}