import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/authentication/views/login_view.dart';
import 'features/authentication/views/home_view.dart';
import 'features/owner/views/owner_dashboard_view.dart';
import 'product_controller.dart'; // import controller ของคุณ
import 'features/cart/cart_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => CartController()),
        // เพิ่ม Provider อื่นๆที่ต้องใช้
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homemade Bliss',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          if (authSnap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = authSnap.data;
          if (user == null) return const LoginView();

          // Logged-in: fetch role and route accordingly
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (roleSnap.hasError) {
                // On error, fallback to customer home
                return const HomeView();
              }
              final data = roleSnap.data?.data();
              final role = (data?['role'] as String?)?.toLowerCase();
              if (role == 'owner') {
                return const OwnerDashboardView();
              }
              return const HomeView();
            },
          );
        },
      ),
    );
  }
}

// For test compatibility: provide the expected class name
class HomemadeBlissApp extends MyApp {
  const HomemadeBlissApp({super.key});
}
