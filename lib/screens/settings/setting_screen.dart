// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillswap/utils/navigation_helper.dart';
import '../../services/firestore_service.dart';
import '../../models/usermodel.dart';
import '../../widgets/animation/fade_animation.dart'; // Assuming you have these animation widgets
import '../../widgets/animation/slide_animation.dart'; // Assuming you have these animation widgets

class SettingsScreen extends StatelessWidget {
  final FirestoreService _fs = FirestoreService();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Please login to view settings')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent light background
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor, // Themed app bar
        foregroundColor: Colors.white, // White text/icons
        elevation: 0, // Flat app bar
      ),
      body: StreamBuilder<UserModel?>(
        stream: _fs.getUserStream(currentUser.uid),
        builder: (context, snapshot) {
          final user = snapshot.data;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Consistent padding
            children: [
              // Profile Settings Card
              SlideAnimation(
                direction: SlideDirection.fromLeft,
                delay: const Duration(milliseconds: 200),
                child: Card(
                  elevation: 5, // Lifted card
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners
                  margin: EdgeInsets.zero, // Remove default card margin
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // More padding
                    leading: Icon(Icons.person, color: Theme.of(context).colorScheme.secondary, size: 28),
                    title: Text(
                      'Profile Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      currentUser.email ?? 'No email',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
                    onTap: () {
                      NavigationHelper.navigateToEditProfile(context);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16), // Space between cards

              // General Settings Card
              SlideAnimation(
                direction: SlideDirection.fromRight,
                delay: const Duration(milliseconds: 300),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(
                          'Available for Exchanges',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Make your profile visible to others',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                        value: user?.isAvailable ?? true,
                        onChanged: (value) {
                          _fs.updateAvailability(currentUser.uid, value);
                        },
                        activeColor: Theme.of(context).colorScheme.primary, // Themed switch color
                      ),
                      // Add more general settings here if needed
                      // const Divider(indent: 20, endIndent: 20, height: 1), // Optional divider within card
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Information & Support Card
              SlideAnimation(
                direction: SlideDirection.fromLeft,
                delay: const Duration(milliseconds: 400),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary, size: 28),
                        title: Text(
                          'About SkillSwap',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'SkillSwap',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2024 SkillSwap',
                            children: [
                              Text(
                                'A platform for exchanging skills and knowledge.',
                                style: Theme.of(context).textTheme.bodyMedium, // Themed text
                              ),
                            ],
                          );
                        },
                      ),
                      // Add more info/support options here if needed
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Account Actions Card
              SlideAnimation(
                direction: SlideDirection.fromRight,
                delay: const Duration(milliseconds: 500),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Icon(Icons.logout, color: Colors.orange, size: 28), // Distinct color for Logout
                        title: Text(
                          'Logout',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
                        onTap: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
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
                      const Divider(indent: 20, endIndent: 20, height: 1), // Divider within the card
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Icon(Icons.delete_forever, color: Colors.red, size: 28), // Distinct color for Delete
                        title: Text(
                          'Delete Account',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.red),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
                        onTap: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Text(
                                'Are you sure you want to delete your account? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
                            } on FirebaseAuthException catch (e) {
                              String errorMessage = 'Failed to delete account. Please try again.';
                              if (e.code == 'requires-recent-login') {
                                errorMessage = 'Please re-authenticate recently to delete your account.';
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorMessage)),
                                );
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
                  ),
                ),
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          );
        },
      ),
    );
  }
}