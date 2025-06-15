import 'package:firebase_auth/firebase_auth.dart';

import '../firestore_service.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  FirestoreService get firestoreService => _firestoreService;

  Future<User?> signUp(String name, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Use the centralized method to create the user document
        await _firestoreService.createUserDocument(user.uid, name, email);
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
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) { // <--- Catch the FirebaseAuthException
      print('Login Error (AuthService): ${e.code} - ${e.message}'); // Log for debugging
      rethrow; // <--- CRITICAL: RE-THROW THE EXCEPTION
    } catch (e) { // Catch any other unexpected non-Firebase Auth exceptions
      print('Login Error (AuthService - General): $e');
      rethrow; // Re-throw general exceptions too, or handle differently if preferred
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();                           // Firebase method jo user ko logout kar deta hai
  }

  // Get current user
  User? get currentUser => _auth.currentUser;       // Ye property current logged in user ko return karti hai, agar koi login ho
}
