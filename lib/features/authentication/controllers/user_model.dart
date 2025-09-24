// User Model (ข้อมูลผู้ใช้)
// EN: User data model

class UserModel {
  final String uid;
  final String email;
  final String? displayName;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
  });
}