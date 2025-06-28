// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Make sure this import is present for GeoPoint
import '../../models/usermodel.dart';
import '../../services/fcm_services.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../utils/navigation_helper.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel currentUser;
  const ProfileScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {



  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    final GeoPoint? userLocation = widget.currentUser.location;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: FirestoreService().getUserStream(userId),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user == null) {
            return const Center(child: Text('User not found.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Since we're using a StreamBuilder, data will refresh automatically
              // when the source changes. This delay just provides a visual cue.
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  _buildProfileHeader(context, user),
                  const SizedBox(height: 20),
                  RepaintBoundary(child: _buildStatsRow(context, user)),
                  const SizedBox(height: 24),
                  RepaintBoundary(child: _buildQuickActions(context, user)),
                  const SizedBox(height: 24),
                  RepaintBoundary(
                    child: _buildSkillsSection(
                      context,
                      'Skills I Can Teach',
                      user.skillsToTeach,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RepaintBoundary(
                    child: _buildSkillsSection(
                      context,
                      'Skills I Want to Learn',
                      user.skillsToLearn,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FirestoreService().verifyFCMSetup();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('FCM setup verified - check console logs')),
                      );
                    },
                    child: const Text('Verify FCM Setup'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FCMService.sendPushMessage(
                        token: 'cRuA-yzWSaSTvmMDGlv22U:APA91bFcnCWSQ5hlo6TWHG_a8rHQ7DCRomMIX81CGb6891ZFzvSHIQkuAlEhIGNB2YnkARP836Xsf7D-xdhdvFwoxwBVBchC3Wf3up5id2sIMjCigIp3l9s',
                        title: '🎉 It works!',
                        body: 'Notification from SkillSwap app!',
                      );
                    },
                    child: const Text('Send Test Notification'),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    // No need for GeoPoint userLocation variable here if you're not doing on-the-fly geocoding
    // final GeoPoint? userLocation = user.location;

    return Column(
      children: [
        const SizedBox(
          height: 12,
        ),
        CircleAvatar(
          radius: 60,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          backgroundImage: user.profileImageUrl != null
              ? CachedNetworkImageProvider(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? Icon(
            Icons.person,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        // --- CHANGED BLOCK BELOW ---
        if (user.locationName != null && user.locationName!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Location: ${user.locationName!}', // Directly use locationName from UserModel
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ] else if (user.location != null) ...[ // Fallback if locationName somehow got cleared or is old data
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              // Optional: You could keep a FutureBuilder here as a fallback
              // for old data or if locationName somehow becomes null.
              // However, the primary goal is to have locationName always populated.
              Text(
                'Location: Unknown Location (Refresh Profile in Edit Screen)', // Suggest action
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
            ],
          ),
        ],
        // --- END CHANGED BLOCK ---
        if (user.bio != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              user.bio!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, UserModel user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            _buildStatCard(
              context,
              'Rating',
              user.rating.toStringAsFixed(1),
              Icons.star,
              Colors.amber,
            ),
            _buildStatCard(
              context,
              'Exchanges',
              '${user.totalExchanges}',
              Icons.swap_horiz,
              Colors.blue,
            ),
            _buildStatCard(
              context,
              'Status',
              user.isAvailable ? 'Available' : 'Busy',
              user.isAvailable ? Icons.check_circle : Icons.cancel,
              user.isAvailable ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color iconColor,
      )
  {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: iconColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserModel user) {
    return Column(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              Icons.swap_horiz,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Exchange Requests'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => NavigationHelper.navigateToExchangeRequests(context),
          ),
        ),
        const SizedBox(height: 5),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              Icons.star,
              color: Colors.amber,
            ),
            title: const Text('Reviews'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => NavigationHelper.navigateToReviews(context, user),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(BuildContext context, String title, List<String> skills) {
    final bool isTeaching = title.toLowerCase().contains('teach');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🧾 Section Heading
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            thickness: 2,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            endIndent: 240,
          ),
          const SizedBox(height: 16),

          // 🔲 Empty state or List view
          skills.isEmpty
              ? Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1), // Use a lighter color for visibility
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(20),
            child: Text(
              'No ${isTeaching ? 'skills to teach' : 'skills to learn'} yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          )
              : Column(
            children: skills.take(5).map((skill) {
              // ⭐️ This is the updated code to match the Quick Actions UI
              return Card(
                // Match the elevation and border radius
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // Add a margin to space the cards, similar to your original design
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  // Use the icon from your original skills section
                  leading: Icon(
                    Icons.check_circle_outline,
                    // ⚠️ Note: I am setting the icon color to the secondary color for better visibility.
                    // In your original code, the icon and background had the same primary color, which made the icon invisible.
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(
                    skill,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  // You can add a trailing icon to match Quick Actions, if you want.
                  // trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Add your onTap logic here if needed
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }



}