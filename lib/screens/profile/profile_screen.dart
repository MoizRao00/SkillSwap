// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Make sure this import is present for GeoPoint
import '../../models/usermodel.dart';
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

  late LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(); // Initialize the service
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    // Define userLocation at a scope where it's accessible by FutureBuilder
    final GeoPoint? userLocation = user.location; // <-- Define it here

    return Column(
      children: [
        const SizedBox(
          height: 12,
        ),
        CircleAvatar(
          radius: 60,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
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
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (userLocation != null) ...[ // Now use userLocation here
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              // The userLocation variable is now correctly scoped here
              FutureBuilder<String>(
                future: _locationService.getCityName(userLocation.latitude, userLocation.longitude), // Use userLocation
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    // It's good to show the error message for debugging
                    return Text('Location: Error (${snapshot.error})');
                  } else {
                    // Fallback if snapshot.data is null, though getCityName returns 'Unknown Location'
                    return Text('Location: ${snapshot.data ?? 'Unknown Location'}');
                  }
                },
              ),
            ],
          ),
        ],
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
      ) {
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
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.secondary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // Brings it into line with rest of screen
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          skills.isEmpty
              ? Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No ${title.toLowerCase().contains('teach') ? 'skills to teach' : 'skills to learn'} yet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
          )
              : Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.take(5).map((skill) {
                return Chip(
                  label: Text(
                    skill,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}