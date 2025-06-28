import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillswap/screens/auth/auth_screen.dart';
import 'package:skillswap/screens/home/home_screen.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'package:skillswap/services/firestore_service.dart';
import 'screens/auth/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Handle errors
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show splash screen while waiting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // User is logged in
          if (snapshot.hasData) {
            return FutureBuilder<bool>(
              future: FirestoreService().ensureUserDocumentExists(),
              builder: (context, userDocSnapshot) {
                if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }

                if (userDocSnapshot.hasError || userDocSnapshot.data == false) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text('Error initializing user profile'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              FirebaseAuth.instance.signOut();
                            },
                            child: const Text('Sign Out and Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const HomeScreen();
              },
            );
          }

          // User is not logged in
          return const AuthScreen();
        },
      ),
    );
  }
}