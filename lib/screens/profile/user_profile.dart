import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ensure this import is present for GeoPoint
import '../../models/review_model.dart';
import '../../models/usermodel.dart';
import '../../services/firestore_service.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/animation/fade_animation.dart';
import '../../widgets/animation/slide_animation.dart';

class UserProfileScreen extends StatelessWidget {
  final UserModel user;
  final FirestoreService _fs = FirestoreService();

  UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar with profile picture and basic info
          SliverAppBar(
            expandedHeight: 250, // Increased height for more space
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context),
            ), // Pass context
          ),
          // Profile Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Basic Info Card
                FadeAnimation(child: _buildBasicInfo(context)),

                // Stats Card
                SlideAnimation(
                  direction: SlideDirection.fromRight,
                  child: _buildStats(context),
                ),

                // Skills Section
                SlideAnimation(
                  direction: SlideDirection.fromLeft,
                  child: _buildSkillsSection(context),
                ),

                // Reviews Section
                FadeAnimation(child: _buildReviewsSection(context)),

                // Action Buttons
                SlideAnimation(
                  direction: SlideDirection.fromBottom,
                  child: _buildActionButtons(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MODIFIED _buildHeader method
  Widget _buildHeader(BuildContext context) {
    // context is now passed
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4ED7F1), Color(0xFF6FE6FC)],
            ),
          ),
        ),

        // Profile picture and name positioned at the bottom
        Align(
          // Use Align to position the content precisely
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 24.0,
            ), // Adjust this value to move it lower/higher
            child: Column(
              mainAxisSize: MainAxisSize.min, // Take minimum space needed
              children: [
                // Rectangular border around a Circular Avatar
                Container(
                  width: 110, // Width of the rectangular container/border
                  height: 110, // Height of the rectangular container/border
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.2,
                    ), // Light background for the border container
                    borderRadius: BorderRadius.circular(
                      60.0,
                    ), // Rounded corners for the rectangular container
                    border: Border.all(
                      color: Colors.white.withOpacity(
                        0.7,
                      ), // Color of the border
                      width: 2.0, // Width of the border
                    ),
                  ),
                  child: Center(
                    // Center the CircleAvatar inside the rectangular container
                    child: CircleAvatar(
                      radius: 50, // Radius of the circular avatar itself
                      backgroundColor: Theme.of(context).colorScheme.primary
                          .withOpacity(0.1), // Placeholder background
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user.profileImageUrl == null
                          ? Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      ) // Icon for placeholder
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.locationName!}',
                        style: TextStyle(color: Colors.white)
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.bio != null) ...[
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(user.bio!),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Member since ${_formatDate(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              'Rating',
              user.rating.toStringAsFixed(1),
              Icons.star,
              Colors.amber,
            ),
            _buildStatItem(
              context,
              'Exchanges',
              user.totalExchanges.toString(),
              Icons.swap_horiz,
              Colors.blue,
            ),
            _buildStatItem(
              context,
              'Status',
              user.isAvailable ? 'Available' : 'Busy',
              user.isAvailable ? Icons.check_circle : Icons.do_not_disturb,
              user.isAvailable ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      )
  {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildSkillsList(
            context,
            'Teaching',
            user.skillsToTeach,
            Icons.school,
          ),
          const SizedBox(height: 16),
          _buildSkillsList(
            context,
            'Learning',
            user.skillsToLearn,
            Icons.psychology,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsList(
      BuildContext context,
      String title,
      List<String> skills,
      IconData icon,
      )
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            return Chip(
              label: Text(skill),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () =>
                    NavigationHelper.navigateToReviews(context, user),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Review>>(
            stream: _fs.getUserReviews(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No reviews yet'),
                  ),
                );
              }

              return Column(
                children: reviews.take(3).map((review) {
                  return _ReviewCard(review: review);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Request Exchange'),
              onPressed: () =>
                  NavigationHelper.navigateToCreateExchange(context, user),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.report),
            onPressed: () {
              // Show report user dialog
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                const Spacer(),
                // Date
                Text(
                  _formatDate(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}