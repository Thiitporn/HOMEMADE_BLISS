import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/authentication/controllers/auth_controller.dart';
import 'util/theme/theme.dart';
import 'features/authentication/views/login_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: const HomemadeBlissApp(),
    ),
  );
}

class HomemadeBlissApp extends StatelessWidget {
  const HomemadeBlissApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      home: const LoginView(),
    );
  }
}