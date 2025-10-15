import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _shopPhoneCtrl = TextEditingController();
  String? _email;
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    setState(() {
      _displayNameCtrl.text = data['displayName'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _email = data['email'] ?? '';
      _role = data['role'] ?? '';
      if (_role == 'owner') {
        _shopNameCtrl.text = data['shopName'] ?? '';
        _shopAddressCtrl.text = data['shopAddress'] ?? '';
        _shopPhoneCtrl.text = data['shopPhone'] ?? '';
      }
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;
    final displayName = _displayNameCtrl.text.trim();
    final updateData = {
      'displayName': displayName,
      'phone': _phoneCtrl.text.trim(),
    };
    if (_role == 'owner') {
      updateData['shopName'] = _shopNameCtrl.text.trim();
      updateData['shopAddress'] = _shopAddressCtrl.text.trim();
      updateData['shopPhone'] = _shopPhoneCtrl.text.trim();
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);
    // อัปเดต displayName ใน Firebase Auth ด้วย
    if (user != null && user.displayName != displayName) {
      await user.updateDisplayName(displayName);
      await user.reload();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _phoneCtrl.dispose();
    _shopNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    _shopPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขโปรไฟล์')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _displayNameCtrl,
                    decoration: const InputDecoration(labelText: 'ชื่อที่แสดง'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'เบอร์โทร'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกเบอร์โทร' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(labelText: 'อีเมล'),
                    enabled: false,
                  ),
                  if (_role == 'owner') ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const Text('ข้อมูลร้าน', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shopNameCtrl,
                      decoration: const InputDecoration(labelText: 'ชื่อร้าน'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shopAddressCtrl,
                      decoration: const InputDecoration(labelText: 'ที่อยู่ร้าน'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shopPhoneCtrl,
                      decoration: const InputDecoration(labelText: 'เบอร์ร้าน'),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('บันทึก'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
