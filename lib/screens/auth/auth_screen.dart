import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // Corrected: Single declaration of FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Initialize GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();


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

  // --- Login and Signup Methods ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Login with Email/Password
        await _auth.signInWithEmailAndPassword( // Use _auth instance
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // After successful login, save the "Remember Me" preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', _rememberMe);
        print('Remember Me preference saved: $_rememberMe');

      } else {
        // Sign up with Email/Password
        final userCredential = await _auth.createUserWithEmailAndPassword( // Use _auth instance
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Update display name
        await userCredential.user?.updateDisplayName(_nameController.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided for that user.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
        } else if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else {
          message = 'An authentication error occurred: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Google Sign-In Method ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true); // Show loading
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        print("Google login cancelled");
        return;
      }


      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential); // Use _auth instance
      print("Google login successful!");
      // No explicit navigation here, as App() handles based on authStateChanges
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth error during Google sign-in: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Error: ${e.message}')),
        );
      }
    } catch (e) {
      print("Error during Google sign-in: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in with Google: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Hide loading
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF00CAFF), // Corrected Color syntax
                  Colors.white
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(

              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child:
                      Column(
                        children: [
                          Image.asset(
                            "assets/icon2.png",
                            width: 200,
                            height: 160,
                          ),
                          Text(
                            'SkillSwap',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5,),

                          Text(
                            'Exchange Skills, Grow Together',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.black,
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
                                        prefixIcon: const Icon(Icons.person),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
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
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16), // Spacing before Remember Me

                                // Remember Me checkbox (only for Login mode)
                                if (_isLogin)
                                  CheckboxListTile(
                                    title: const Text("Remember Me"),
                                    value: _rememberMe,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _rememberMe = newValue!;
                                      });
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                if (_isLogin) const SizedBox(height: 8),

                                const SizedBox(height: 24),

                                // Main Email/Password Submit button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white, // Ensure visibility on button
                                    ),
                                  )
                                      : Text(_isLogin ? 'Login' : 'Sign Up'),
                                ),
                                const SizedBox(height: 16),

                                // "OR" separator
                                const Text(
                                  'OR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),

                                // Google Login Button
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _signInWithGoogle,
                                  icon: const Icon(Icons.g_mobiledata), // Google icon
                                  label: const Text('Login with Google'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red, // Google's brand color
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Toggle button (Create Account / Already have an account)
                                TextButton(
                                  onPressed: () {
                                    if (_isLoading) return; // Prevent switching while loading
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _animationController.reset();
                                      _animationController.forward();
                                      _emailController.clear();
                                      _passwordController.clear();
                                      _nameController.clear();
                                      _rememberMe = false; // Reset remember me on mode switch
                                    });
                                  },
                                  child: Text(
                                    _isLogin
                                        ? 'Create new account'
                                        : 'Already have an account?',
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
          ),
        ],
      ),
    );
  }
}