import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // เพิ่ม import Firestore

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptPolicy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _shopNameCtrl.dispose();
    super.dispose();
  }

  Future<String?> _signup(
    String email,
    String password,
    String username,
    String role,
    String phone,
    String address,
    String shopName,
  ) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // บันทึกข้อมูลผู้ใช้ลง Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'username': username,
        'email': email,
        'role': role, // owner หรือ customer
        'phone': phone,
        'address': address,
        'shopName': shopName,
        'uid': cred.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Signup failed';
    } catch (_) {
      return 'Signup failed';
    }
  }

  bool _isPasswordSecure(String password) {
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$&*~]'));
    return password.length >= 8 && hasUpper && hasLower && hasDigit && hasSpecial;
  }

  @override
  Widget build(BuildContext context) {
    // Minimal brown tones
    final Color darkBrown = const Color(0xFF4E342E);
    final Color mediumBrown = const Color(0xFF8D6E63);
    final Color lightBrown = const Color(0xFFD7CCC8);
    final Color cream = const Color(0xFFFAF3EF);
    final Color borderColor = const Color(0xFFE0CFC2);
    final Color buttonTextColor = Colors.white;

    // Password strength indicators
    final password = _pwdCtrl.text;
    final isLengthOk = password.length >= 8;
    final isUniqueOk = password.contains(RegExp(r'[!@#\$&*~]'));

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            iconSize: 40, // เพิ่มขนาดปุ่ม
            padding: EdgeInsets.zero, // ลด padding เพื่อให้ขนาด container มีผลจริง
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40), // เพิ่ม hit area
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: lightBrown,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.arrow_back, color: darkBrown, size: 24), // ขนาด icon มาตรฐาน
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.cookie, color: mediumBrown, size: 22), // เปลี่ยนเป็นคุกกี้
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
              const SizedBox(height: 4),
              Text(
                'Create your account', // เปลี่ยนหัวข้อ
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: darkBrown,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Please enter your details', // เปลี่ยน subtitle
                style: TextStyle(fontSize: 13, color: darkBrown.withOpacity(0.7)),
              ),
              const SizedBox(height: 18),
              // Username
              _InputField(
                controller: _nameCtrl,
                label: 'Username',
                hint: 'Username',
                brown: darkBrown,
                borderColor: borderColor,
                fillColor: Colors.white,
                dense: true, // เพิ่ม dense
              ),
              const SizedBox(height: 10),
              // Email
              _InputField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'example@gmail.com',
                brown: darkBrown,
                borderColor: borderColor,
                fillColor: Colors.white,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) return 'Invalid email format';
                  return null;
                },
                dense: true,
              ),
              const SizedBox(height: 10),
              // Phone
              _InputField(
                controller: _phoneCtrl,
                label: 'Phone',
                hint: 'Phone number',
                brown: darkBrown,
                borderColor: borderColor,
                fillColor: Colors.white,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your phone number';
                  return null;
                },
                dense: true,
              ),
              const SizedBox(height: 10),
              // Address
              _InputField(
                controller: _addressCtrl,
                label: 'Address',
                hint: 'Shop address',
                brown: darkBrown,
                borderColor: borderColor,
                fillColor: Colors.white,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your address';
                  return null;
                },
                dense: true,
              ),
              const SizedBox(height: 10),
              // Shop Name
              _InputField(
                controller: _shopNameCtrl,
                label: 'Shop Name',
                hint: 'Shop name',
                brown: darkBrown,
                borderColor: borderColor,
                fillColor: Colors.white,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your shop name';
                  return null;
                },
                dense: true,
              ),
              const SizedBox(height: 10),
              // Password
              _InputField(
                controller: _pwdCtrl,
                label: 'Password',
                hint: 'Password', // เปลี่ยน placeholder
                brown: darkBrown,
                borderColor: borderColor,
                fillColor: Colors.white,
                obscureText: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: mediumBrown, size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your password';
                  if (!_isPasswordSecure(value)) {
                    return 'Password must be at least 8 characters\nInclude uppercase, lowercase, number, and special character';
                  }
                  return null;
                },
                dense: true,
              ),
              const SizedBox(height: 10),
              // Confirm Password
              _InputField(
                controller: _confirmPwdCtrl,
                label: 'Confirm Password',
                hint: 'Confirm password', // เปลี่ยน placeholder
                brown: darkBrown,
                borderColor: borderColor,
                fillColor: Colors.white,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: mediumBrown, size: 18),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your password';
                  if (value != _pwdCtrl.text) return 'Passwords do not match';
                  return null;
                },
                dense: true,
              ),
              const SizedBox(height: 10),
              // Password strength indicators
              Row(
                children: [
                  Icon(Icons.circle, color: isLengthOk ? mediumBrown : borderColor, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'At least 8 character',
                    style: TextStyle(
                      color: isLengthOk ? mediumBrown : borderColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.circle, color: isUniqueOk ? mediumBrown : borderColor, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'Include unique character',
                    style: TextStyle(
                      color: isUniqueOk ? mediumBrown : borderColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Accept Policy Checkbox (default: checkbox left)
              CheckboxListTile(
                value: _acceptPolicy,
                onChanged: (v) => setState(() => _acceptPolicy = v ?? false),
                title: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: darkBrown, // ปรับสีข้อความให้ contrast สูงขึ้น
                      fontSize: 13, // เพิ่มขนาดเล็กน้อย
                      fontWeight: FontWeight.w600, // เพิ่มน้ำหนัก
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms Of Service',
                        style: TextStyle(
                          color: darkBrown, // ใช้สีเข้มเหมือนข้อความหลัก
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: darkBrown, // ใช้สีเข้มเหมือนข้อความหลัก
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF4C352A), // น้ำตาลเข้ม
                checkColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              // Signup Button
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
                  onPressed: _isLoading || !_acceptPolicy
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          setState(() => _isLoading = true);
                          String? error;
                          try {
                            final role = 'owner'; // เปลี่ยนเป็น 'owner' สำหรับเจ้าของร้าน
                            error = await _signup(
                              _emailCtrl.text.trim(),
                              _pwdCtrl.text.trim(),
                              _nameCtrl.text.trim(),
                              role,
                              _phoneCtrl.text.trim(),
                              _addressCtrl.text.trim(),
                              _shopNameCtrl.text.trim(),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }

                          if (!mounted) return;

                          if (error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Sign up successful'),
                                backgroundColor: mediumBrown,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.of(context).pop();
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
                      : const Text('Signup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              // Already member? Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already a member? ', style: TextStyle(fontSize: 13, color: darkBrown.withOpacity(0.8))),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 13,
                        color: darkBrown, // ใช้สีเข้มเหมือนปุ่ม Sign Up หน้า Login
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom input field widget for rounded border and shadow
class _InputField extends StatelessWidget {
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
  final bool dense; // เพิ่ม property

  const _InputField({
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