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
import 'features/orders/views/payment_view.dart';
import 'features/orders/views/success_view.dart';
import 'common/stripe_config.dart';
import 'common/notification_service.dart';
import 'common/push_notification_service.dart';
import 'util/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // ตั้งค่า Stripe ให้ถูกต้องก่อน runApp (ดึงจาก backend ให้ตรงกับ secret key)
  await StripeConfig.ensureInitialized();
  // Initialize notifications (Android will request permission on 13+)
  await NotificationService.init();
  await PushNotificationService.init();
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
      navigatorKey: NotificationService.navigatorKey,
      title: 'Homemade Bliss',
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      themeMode: ThemeMode.system,
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
                  final role = data?['role']?.toLowerCase() ?? 'customer';
              if (role == 'owner') {
                return const OwnerDashboardView();
              }
              return const HomeView();
            },
          );
        },
      ),
      routes: {
        '/payment': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PaymentView(orderData: args);
        },
        '/order-success': (context) => const OrderSuccessView(),
      },
    );
  }
}

// For test compatibility: provide the expected class name
class HomemadeBlissApp extends MyApp {
  const HomemadeBlissApp({super.key});
}
