// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/usermodel.dart';
import '../../services/firestore_service.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/animation/fade_animation.dart';
import '../../widgets/animation/slide_animation.dart';
import 'edit_profile_screen.dart'; // Ensure this import is correct and EditProfileScreen exists

// Assuming you have a Review model or similar for _ReviewCard.
// If Review is not defined, you'll need to define it or remove _ReviewCard.
// For now, I'll keep it as it was in your previous snippet.
class Review {
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({required this.rating, required this.comment, required this.createdAt});
}


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

      body: StreamBuilder<UserModel?>(
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
              setState(() {}); // Refresh the StreamBuilder
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Consistent padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Center items in the column
                children: [
                  // Profile Picture with animation
                  FadeAnimation(
                    child: Hero(
                      tag: 'profile_picture',
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Add profile picture upload logic here, perhaps navigate to EditProfileScreen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile picture upload coming soon! (Tap Edit button to manage)'),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 60, // Slightly larger avatar
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          backgroundImage: user.profilePicUrl != null
                              ? NetworkImage(user.profilePicUrl!)
                              : null,
                          child: user.profilePicUrl == null
                              ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Adjusted spacing

                  // Name with animation
                  SlideAnimation(
                    direction: SlideDirection.fromRight,
                    child: Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
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
                          Icon(Icons.location_on, size: 18, color: Colors.grey[600]), // Slightly larger icon, themed
                          const SizedBox(width: 6),
                          Text(
                            user.location!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bio with animation
                  if (user.bio != null) ...[
                    FadeAnimation(
                      delay: const Duration(milliseconds: 300),
                      child: Padding( // Add padding to bio text for better readability
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          user.bio!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // Increased spacing
                  ],

                  // Stats Card with animation - RESTRUCTURED TO MATCH DASHBOARD
                  SlideAnimation(
                    direction: SlideDirection.fromBottom,
                    delay: const Duration(milliseconds: 400),
                    child: Card(
                      elevation: 6, // Outer card elevation
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Outer card rounded corners
                      margin: EdgeInsets.zero, // Remove default card margin
                      shadowColor: Colors.black.withOpacity(0.2), // Subtle shadow
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0), // Outer card padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded( // Each stat wrapped in Expanded
                              child: _buildStat(
                                context, // Pass context
                                'Rating',
                                user.rating.toStringAsFixed(1), // Formats rating to 1 decimal place
                                Icons.star,
                                Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 8), // Reduced space
                            Expanded(
                              child: _buildStat(
                                context, // Pass context
                                'Exchanges',
                                user.totalExchanges.toString(),
                                Icons.swap_horiz,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8), // Reduced space
                            Expanded(
                              child: _buildStat(
                                context, // Pass context
                                'Status',
                                user.isAvailable ? 'Available' : 'Busy',
                                user.isAvailable ? Icons.check_circle : Icons.do_not_disturb,
                                user.isAvailable ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32), // More spacing

                  // Quick Actions with animations - STYLED AS CARDS
                  SlideAnimation(
                    direction: SlideDirection.fromLeft,
                    delay: const Duration(milliseconds: 500),
                    child: Column( // Wrapped in Column to apply consistent margins
                      children: [
                        Card(
                          elevation: 3, // Consistent card elevation
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.zero, // Remove default margin from Card
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjusted padding
                            leading: Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.secondary, size: 28), // Themed icon
                            title: Text(
                              'Exchange Requests',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
                            onTap: () => NavigationHelper.navigateToExchangeRequests(context),
                          ),
                        ),
                        const SizedBox(height: 12), // Consistent spacing between cards
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: Icon(Icons.star, color: Theme.of(context).colorScheme.secondary, size: 28),
                            title: Text(
                              'Reviews',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
                            onTap: () => NavigationHelper.navigateToReviews(context, user),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32), // More spacing

                  // Skills sections with animations - STYLED FOR CONSISTENCY
                  SlideAnimation(
                    direction: SlideDirection.fromRight,
                    delay: const Duration(milliseconds: 600),
                    child: _buildSkillsSection(
                      context,
                      'Skills I Can Teach',
                      user.skillsToTeach,
                    ),
                  ),
                  const SizedBox(height: 24), // Adjusted spacing
                  SlideAnimation(
                    direction: SlideDirection.fromLeft,
                    delay: const Duration(milliseconds: 700),
                    child: _buildSkillsSection(
                      context,
                      'Skills I Want to Learn',
                      user.skillsToLearn,
                    ),
                  ),
                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // MODIFIED _buildStat to look like Dashboard's _buildStatCard
  Widget _buildStat(
      BuildContext context, // Now accepts context
      String label,
      String value,
      IconData icon, // Now accepts icon
      Color color, // Now accepts color
      ) {
    return Card(
      elevation: 2.0, // Reduced elevation for inner cards
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Slightly less rounded than outer card
      margin: EdgeInsets.zero, // Ensure no internal margin from Card
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8), // Adjusted padding inside the stat card
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon, // Use the passed icon
              color: color, // Use the passed color
              size: 28, // Consistent icon size
            ),
            const SizedBox(height: 8), // Adjusted spacing
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22, // Adjusted font size for value
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label, // Label goes on one line too
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 12, // Adjusted font size for title
              ),
              textAlign: TextAlign.center,
              maxLines: 1, // Ensure title is on one line
              overflow: TextOverflow.ellipsis, // Truncates if it's too long
            ),
          ],
        ),
      ),
    );
  }


  // _buildQuickActions is now integrated directly into the main Column
  // This empty implementation ensures the original call is still valid.
  // The content is now inline in the main build method.
  Widget _buildQuickActions(BuildContext context, UserModel user) {
    return const SizedBox.shrink(); // This widget is no longer used directly as content is inlined.
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
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 18), // Consistent spacing
        skills.isEmpty
            ? Card( // Wrap "No skills" in a card for consistency
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                // Dynamically adjust the message for clarity
                'No ${title.toLowerCase().replaceAll('skills i can ', '').replaceAll('skills i want to ', '')} yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ),
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
                label: Text(
                  skill,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.white),
                ),
                backgroundColor:
                Theme.of(context).colorScheme.secondary.withOpacity(0.8), // Themed chip background
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Assuming this class is defined elsewhere or should be here.
// If Review is not used or defined, you can remove this.
class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3, // Consistent elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent rounded corners
      margin: const EdgeInsets.only(bottom: 12), // Space between review cards
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
                      size: 18, // Slightly larger stars
                    );
                  }),
                ),
                const Spacer(),
                // Date
                Text(
                  _formatDate(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]), // Themed date text
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium, // Consistent body text style
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}