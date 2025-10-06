import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('สมัครสมาชิก', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // เพิ่ม logic สมัครสมาชิกที่นี่
              },
              child: Text('สมัครสมาชิก'),
            ),
          ],
        ),
      ),
    );
  }
}