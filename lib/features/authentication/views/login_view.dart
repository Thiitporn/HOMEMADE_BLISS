import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF543310), // เปลี่ยนสี AppBarเป็น #543310
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'อีเมล',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'กรุณากรอกอีเมล' : null,
                  onSaved: (value) => _email = value!.trim(),
                ),
                const SizedBox(height: 16),
                // Password Field
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
                  validator: (value) =>
                      value == null || value.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null,
                  onSaved: (value) => _password = value!.trim(),
                ),
                const SizedBox(height: 24),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        authController.login(_email, _password);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(authController.isLoggedIn
                                ? 'Login Success'
                                : 'Login Failed'),
                          ),
                        );
                      }
                    },
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                ),
                const SizedBox(height: 12),
                // Signup Button
                TextButton(
                  onPressed: () {
                    // TODO: ไปหน้าสมัครสมาชิก
                  },
                  child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}