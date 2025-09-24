import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'signup_view.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _name = '';
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สมัครสมาชิก', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF543310),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'กรุณากรอกชื่อ' : null,
                  onSaved: (value) => _name = value!.trim(),
                ),
                const SizedBox(height: 16),
                // Email Field (เหมือน login_view)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'อีเมล',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                    return null;
                  },
                  onSaved: (value) => _email = value!.trim(),
                ),
                const SizedBox(height: 16),
                // Password Field (เหมือน login_view)
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                    if (value.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                    return null;
                  },
                  onSaved: (value) => _password = value!.trim(),
                ),
                const SizedBox(height: 24),
                // Signup Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // TODO: เชื่อมต่อกับ AuthController สำหรับสมัครสมาชิกจริง
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('สมัครสมาชิกสำเร็จ (Demo)')),
                        );
                      }
                    },
                    child: const Text('สมัครสมาชิก'),
                  ),
                ),
                const SizedBox(height: 12),
                // Login Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // กลับไปหน้า Login
                  },
                  child: const Text('มีบัญชีแล้ว? เข้าสู่ระบบ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}