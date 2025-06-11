// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/usermodel.dart';
import '../../services/firestore_service.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/animation/fade_animation.dart';
import '../../widgets/animation/slide_animation.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _fs = FirestoreService();

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
      appBar:
      AppBar(
        title: const Text('Profile'),
        actions: [
          SlideAnimation(
            direction: SlideDirection.fromRight,
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => NavigationHelper.navigateToEditProfile(context),
            ),
          ),
        ],
      ),

      body:
      StreamBuilder<UserModel?>(
        stream: _fs.getUserStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Profile not found'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture with animation
                  FadeAnimation(
                    child: Hero(
                      tag: 'profile_picture',
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Add profile picture upload
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile picture upload coming soon!'),
                            ),
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name with animation
                  SlideAnimation(
                    direction: SlideDirection.fromRight,
                    child: Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location with animation
                  if (user.location != null) ...[
                    SlideAnimation(
                      direction: SlideDirection.fromLeft,
                      delay: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          Text(user.location!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Bio with animation
                  if (user.bio != null) ...[
                    FadeAnimation(
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        user.bio!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stats Card with animation
                  SlideAnimation(
                    direction: SlideDirection.fromBottom,
                    delay: const Duration(milliseconds: 400),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('Rating ⭐ ', '${user.rating}'),
                            _buildStat('Exchanges', '${user.totalExchanges}'),
                            _buildStat(
                              'Status',
                              user.isAvailable ? 'Available' : 'Busy',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions with animations
                  SlideAnimation(
                    direction: SlideDirection.fromLeft,
                    delay: const Duration(milliseconds: 500),
                    child: _buildQuickActions(context, user),
                  ),
                  const SizedBox(height: 24),

                  // Skills sections with animations
                  SlideAnimation(
                    direction: SlideDirection.fromRight,
                    delay: const Duration(milliseconds: 600),
                    child: _buildSkillsSection(
                      context,
                      'Skills I Can Teach',
                      user.skillsToTeach,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideAnimation(
                    direction: SlideDirection.fromLeft,
                    delay: const Duration(milliseconds: 700),
                    child: _buildSkillsSection(
                      context,
                      'Skills I Want to Learn',
                      user.skillsToLearn,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserModel user) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Exchange Requests'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => NavigationHelper.navigateToExchangeRequests(context),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Reviews'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => NavigationHelper.navigateToReviews(context, user),
          ),
        ),
      ],
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

  Widget _buildSkillsSection(
      BuildContext context,
      String title,
      List<String> skills,
      )
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        skills.isEmpty
            ? Text(
          'No ${title.toLowerCase()} yet',
          style: Theme.of(context).textTheme.bodySmall,
        )
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            return FadeAnimation(
              delay: Duration(
                milliseconds: skills.indexOf(skill) * 100,
              ),
              child: Chip(
                label: Text(skill),
                backgroundColor:
                Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}