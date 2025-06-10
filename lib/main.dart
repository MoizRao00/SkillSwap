// Ye main file hai app ka entry point jahan se Flutter app run hoti hai

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart'; // Is file mein MaterialApp aur routes defined hongi

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Firebase init se pehle ye zaroori hota hai
  await Firebase.initializeApp(); // Firebase ko initialize karta hai
  runApp(const App()); // App() widget se pura app start hota hai
}
