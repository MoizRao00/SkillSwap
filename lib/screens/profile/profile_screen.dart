
// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/usermodel.dart';
import '../exchange/exchange_request_list_screen.dart';
import '../review/reviews_list_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _ensureUserProfile();
  }

  Future<void> _ensureUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create new UserModel with initial data
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'New User',
          skillsToTeach: [],
          skillsToLearn: [],
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        // Save to Firestore using the public saveUser method
        await _fs.saveUser(newUser);
      }
    } catch (e) {
      print('❌ Error ensuring user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please login to view profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _fs.getUserStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(
              child: Text('Profile not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: () {
                    // TODO: Add profile picture upload
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile picture upload coming soon!')),
                    );
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: user.profilePicUrl != null
                        ? NetworkImage(user.profilePicUrl!)
                        : null,
                    child: user.profilePicUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),

                // Location
                if (user.location != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      Text(user.location!),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Bio
                if (user.bio != null) ...[
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],

                // Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Rating', '${user.rating}'),
                        _buildStat('Exchanges', '${user.totalExchanges}'),
                        _buildStat('Status', user.isAvailable ? 'Available' : 'Busy'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (user.totalExchanges > 0) ...[
                  const SizedBox(height: 16),
                ],
                Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewsListScreen(user: user),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.star_outline, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reviews',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '${user.reviews.length} reviews from exchanges',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExchangeRequestsListScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exchange Requests',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'View your sent and received skill exchanges',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Skills
                _buildSkillsSection(context, 'Skills I Can Teach', user.skillsToTeach),
                const SizedBox(height: 16),
                _buildSkillsSection(context, 'Skills I Want to Learn', user.skillsToLearn),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSkillsSection(BuildContext context, String title, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        skills.isEmpty
            ? Text('No ${title.toLowerCase()} yet',
            style: Theme.of(context).textTheme.bodySmall)
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map((skill) => Chip(
            label: Text(skill),
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          ))
              .toList(),
        ),
      ],
    );
  }
}
