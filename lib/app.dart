// Ye file pura app wrap karti hai MaterialApp ke andar
// Yahan routes, theme aur home screen define hoti hai

import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SplashScreen(), // App jab open hoti hai to splash screen show hoti hai
    );
  }
}
