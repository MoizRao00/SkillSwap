import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? email;
  String? bio;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;                       // poora map
        print('🔍 Profile data: $data');                // debug print

        setState(() {
          name  = data['name']  ?? '';
          bio   = data['bio']   ?? 'No bio yet';
          email = data.containsKey('email')
              ? data['email']
              : 'No email available';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${name ?? 'Loading...'}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Email: ${email ?? 'Loading...'}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Bio: ${bio ?? 'Loading...'}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) {
                  loadUserData(); // wapas aane par dobara load karo
                });
              },
              child: const Text("Edit Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
