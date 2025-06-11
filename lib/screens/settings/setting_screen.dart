// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/usermodel.dart';

class SettingsScreen extends StatelessWidget {
  final FirestoreService _fs = FirestoreService();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar:
      AppBar(
        title: const Text('Settings'),
      ),
      body: StreamBuilder<UserModel?>(
        stream: _fs.getUserStream(currentUser.uid),
        builder: (context, snapshot) {
          final user = snapshot.data;

          return
            ListView(
            children: [
              // Profile Settings
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile Settings'),
                subtitle: Text(currentUser.email ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to profile settings
                },
              ),
              const Divider(),

              // Availability Toggle
              SwitchListTile(
                title: const Text('Available for Exchanges'),
                subtitle: const Text('Make your profile visible to others'),
                value: user?.isAvailable ?? true,
                onChanged: (value) {
                  _fs.updateAvailability(currentUser.uid, value);
                },
              ),
              const Divider(),

              // About
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About SkillSwap'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'SkillSwap',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 SkillSwap',
                    children: const [
                      Text('A platform for exchanging skills and knowledge.'),
                    ],
                  );
                },
              ),
              const Divider(),

              // Logout
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('Logout'),
                onTap: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                },
              ),
              const Divider(),

              // Delete Account
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text(
                        'Are you sure you want to delete your account? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await currentUser.delete();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}