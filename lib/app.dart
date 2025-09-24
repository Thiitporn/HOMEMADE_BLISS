import 'package:flutter/material.dart';
import 'package:homemade_bliss/util/theme/theme.dart';
// Use this Class to setup themes, initial Bindings, any animation and much

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,     
    );
  }
}