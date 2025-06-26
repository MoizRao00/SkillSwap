
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/auth/authservices.dart';
// No direct import of app_theme.dart is needed here.
// We will use Theme.of(context) to access the colors dynamically.

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _rememberMe = false;
  bool _passwordVisible = false; // State for password visibility

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AuthService _authService = AuthService(); // Ensure this is declared

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _loadRememberMePreference();
    _passwordVisible = false; // Initialize password as hidden
  }

  Future<void> _loadRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- Helper to show SnackBar messages ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // --- Login and Signup Methods ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', _rememberMe);
        print('Remember Me preference saved: $_rememberMe');

      } else {
        await _authService.signUp(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (_isLogin) {
        switch (e.code) {
          case 'user-not-found':
            message = 'No account found with this email. Please check your email or sign up.';
            break;
          case 'wrong-password':
          case 'invalid-credential':
            message = 'Incorrect password or invalid email. Please try again.';
            break;
          case 'invalid-email':
            message = 'The email address is not valid. Please check the format.';
            break;
          case 'user-disabled':
            message = 'This account has been disabled. Please contact support.';
            break;
          case 'too-many-requests':
            message = 'Too many failed attempts. Please try again later.';
            break;
          default:
            message = 'Login failed. An unexpected error occurred. Please try again.';
            break;
        }
      } else { // Handling errors specifically for SIGN UP
        switch (e.code) {
          case 'email-already-in-use':
            message = 'This email is already registered. Please login or use a different email.';
            break;
          case 'weak-password':
            message = 'The password is too weak. Please choose a stronger one (min 6 characters).';
            break;
          case 'invalid-email':
            message = 'The email address is not valid. Please check the format.';
            break;
          case 'too-many-requests':
            message = 'Too many signup attempts. Please try again later.';
            break;
          default:
            message = 'Sign Up failed. An unexpected error occurred. Please try again.';
            break;
        }
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Google Sign-In Method ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google login cancelled");
        _showErrorSnackBar('Google sign-in was cancelled.');
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // This signs in or creates a Firebase Auth user associated with the Google account.
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // --- CORRECTED SECTION FOR FIRESTORE DOCUMENT ---
        // Check if the user's document already exists in Firestore
        // Use .get() for a one-time fetch to check for existence
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) { // If the document DOES NOT exist
          await _authService.firestoreService.createUserDocument(
            user.uid,
            googleUser.displayName ?? googleUser.email.split('@')[0], // Use Google display name, fallback to part of email
            googleUser.email,
          );
        } else {
          // If the document DOES exist, just update lastActive (or other relevant fields)
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'lastActive': DateTime.now().toIso8601String(),
            // Optionally update other fields like profileImageUrl, displayName if they change via Google
          });
        }
      }

      print("Google login successful!");
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth error during Google sign-in: ${e.message}");
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'An account with this email already exists. Try logging in with a different method.';
          break;
        case 'invalid-credential':
          message = 'The provided Google credentials are invalid.';
          break;
        case 'operation-not-allowed':
          message = 'Google sign-in is not enabled for this project. Please contact support.';
          break;
        case 'too-many-requests':
          message = 'Too many Google sign-in attempts. Please try again later.';
          break;
        default:
          message = 'Google Sign-In failed. An unexpected error occurred: ${e.message ?? 'Unknown error'}.';
          break;
      }
      _showErrorSnackBar(message);
    } catch (e) {
      print("Error during Google sign-in: $e");
      _showErrorSnackBar('Failed to sign in with Google: ${e.toString()}. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access theme colors here
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface; // Text color on cards/surfaces
    final Color cardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor; // Get card background color

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  // Use theme colors for the gradient
                  colors: [
                    primaryColor.withOpacity(0.9), // Start with a slightly opaque primary
                    secondaryColor.withOpacity(0.8), // End with a slightly opaque secondary
                    // For a softer look, you might fade to background or a lighter shade
                    // Theme.of(context).colorScheme.background, // Or fade to background color
                  ],
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Card(
                    // Use theme's card color, or fallback to default
                    color: cardColor,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child:
                      Column(
                        children: [
                          // Ensure asset path is correct, consider sizing with MediaQuery
                          Image.asset(
                            "assets/icon2.png",
                            width: 200,
                            height: 160,
                          ),
                          Text(
                            'SkillSwap',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: onSurfaceColor, // Use onSurface for text on colored cards/backgrounds
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5,),
        
                          Text(
                            'Exchange Skills, Grow Together',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: onSurfaceColor.withOpacity(0.7), // Slightly muted color
                            ),
                          ),
                          const SizedBox(height: 8,),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height:15),
                                // Name field (signup only)
                                if (!_isLogin)
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: 'Name',
                                        prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // Themed icon color
                                        // Border and other properties come from InputDecorationTheme
                                      ),
                                      validator: (value) {
                                        if (!_isLogin &&
                                            (value == null || value.isEmpty)) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                if (!_isLogin) const SizedBox(height: 16),
        
                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // Themed icon color
                                    // Border and other properties come from InputDecorationTheme
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        !value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
        
                                // Password field with show/hide button
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_passwordVisible,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // Themed icon color
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Theme.of(context).colorScheme.primary, // Themed icon color
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
        
                                // Remember Me checkbox (only for Login mode)
                                if (_isLogin)
                                  CheckboxListTile(
                                    title: Text(
                                      "Remember Me",
                                      style: TextStyle(color: onSurfaceColor.withOpacity(0.8)), // Themed text color
                                    ),
                                    value: _rememberMe,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _rememberMe = newValue!;
                                      });
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: primaryColor, // Themed active color for checkbox
                                  ),
                                if (_isLogin) const SizedBox(height: 8),
        
                                const SizedBox(height: 24),
        
                                // Main Email/Password Submit button (uses ElevatedButtonThemeData)
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  child: _isLoading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white, // Color set for contrast on button
                                    ),
                                  )
                                      : Text(_isLogin ? 'Login' : 'Sign Up'),
                                ),
                                const SizedBox(height: 16),
        
                                // "OR" separator
                                Text(
                                  'OR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: onSurfaceColor.withOpacity(0.6)), // Themed separator color
                                ),
                                const SizedBox(height: 16),
        
                                // Google Login Button
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _signInWithGoogle,
                                  icon: const Icon(Icons.g_mobiledata),
                                  label: const Text('Login with Google'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red, // Google's brand color, often kept fixed
                                    foregroundColor: Colors.white, // Ensure text is white for contrast
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 0),
        
                                // Toggle button (Create Account / Already have an account)
                                TextButton(
                                  onPressed: () {
                                    if (_isLoading) return;
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _animationController.reset();
                                      _animationController.forward();
                                      _emailController.clear();
                                      _passwordController.clear();
                                      _nameController.clear();
                                      _rememberMe = false;
                                      _passwordVisible = false;
                                    });
                                  },
                                  child: Text(
                                    _isLogin
                                        ? 'Create new account'
                                        : 'Already have an account?',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary), // Themed text button color
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
