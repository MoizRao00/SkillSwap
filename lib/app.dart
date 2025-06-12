// Ye file pura app wrap karti hai MaterialApp ke andar
// Yahan routes, theme aur home screen define hoti hai

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillswap/screens/auth/auth_screen.dart';
import 'package:skillswap/screens/home/home_screen.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'screens/auth/splash_screen.dart'; // Ensure this import is correct

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Uses system theme (light/dark)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // --- Connection State Handling ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a splash screen or loading indicator while Firebase is determining the auth state.
            // This prevents a blank screen or brief flicker of the login screen before auto-login.
            return const SplashScreen(); // Your custom splash screen
          }

          // --- Authentication State Handling ---
          // If snapshot has data, it means a user is logged in.
          // This covers the "Remember Me" functionality provided by Firebase itself.
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // If no user data, show the AuthScreen
          return const AuthScreen();
        },
      ),
    );
  }
}