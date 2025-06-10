import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import '../firestore_service.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<User?> signUp(String name, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 👇 Yahan sab fields save ho rahe hain signup ke waqt
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,         // user ka unique ID
          'name': name,            // user ka naam
          'email': email,          // AB email bhi yahan save!
          'bio': '',               // initial bio blank
        });
      }
      return user;
    } catch (e) {
      print('Signup Error: $e');
      return null;
    }
  }



// Login existing user
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result =
      await _auth.signInWithEmailAndPassword(email: email, password: password);  // Login Firebase se
      return result.user;                            // User return karta hai agar login successful ho
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();                           // Firebase method jo user ko logout kar deta hai
  }

  // Get current user
  User? get currentUser => _auth.currentUser;       // Ye property current logged in user ko return karti hai, agar koi login ho
}
