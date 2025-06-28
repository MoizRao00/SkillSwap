import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/usermodel.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/navigation_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _fs = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // No longer need _currentUser or _currentUserModelStream as state variables.
  // We'll directly use the StreamBuilder in the build method.

  @override
  void initState() {
    super.initState();
    // No need to set up streams here as the StreamBuilder in build handles it.
  }

  @override
  Widget build(BuildContext context) {
    // Ensure FirebaseAuth.instance.currentUser is not null before proceeding
    // The previous code already assumes this and provides a 'null' fallback.
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      // This case should ideally be handled by your routing or authentication
      // flow, ensuring a logged-in user before reaching the dashboard.
      // For safety, we return a simple loading or error message.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Or a message like "User not logged in."
      );
    }

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        // Use the current user's UID to fetch their UserModel
        stream: _fs.getUserStream(currentUserId),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error loading user data for dashboard: ${snapshot.error}");
            return const Center(child: Text('Error loading your profile. Please try again.'));
          }

          if (user == null) {
            // This case would mean user data doesn't exist for the logged-in UID.
            // Highly unlikely if user creation is robust.
            return const Center(child: Text('User profile not found.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Since we are using streams, data updates automatically.
              // This just provides a visual refresh indicator.
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                RepaintBoundary(child: WelcomeCard(user: user)),
                const SizedBox(height: 24),
                RepaintBoundary(child: StatsOverview(user: user)),
                const SizedBox(height: 32),

                // --- Corrected NearbyUsersSection usage ---
                if (user.location != null) // Only show nearby users if the user's location is set
                  RepaintBoundary(
                    child: NearbyUsersSection(
                      currentUserLocation: user.location!, // Pass the GeoPoint location
                      currentUserId: user.uid,              // Pass the current user's UID
                    ),
                  )
                else
                // Display a message if the user's location is not set
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "To find nearby users, please set your location in your profile!",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                            ),
                            SizedBox(height: 10),

                          ],
                        ),
                      ),
                    ),
                  ),
                // --- End NearbyUsersSection correction ---

                const SizedBox(height: 32),
                RepaintBoundary(
                  child: SkillMatchesSection(
                    currentUserSkillsToTeach: user.skillsToTeach,
                    currentUserSkillsToLearn: user.skillsToLearn,
                    currentUserId: user.uid,
                  ),
                ),
                const SizedBox(height: 32),
                const RepaintBoundary(child: RecentActivitiesSection()),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}


// Welcome Card
class WelcomeCard extends StatelessWidget {
  final UserModel user;

  const WelcomeCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              backgroundImage: user.profileImageUrl != null
                  ? CachedNetworkImageProvider(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Stats Overview
class StatsOverview extends StatelessWidget {
  final UserModel user;

  const StatsOverview({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatTile(context, 'Teaching', '${user.skillsToTeach.length}', Icons.school),
            _buildStatTile(context, 'Learning', '${user.skillsToLearn.length}', Icons.psychology),
            _buildStatTile(context, 'Exchanges', '${user.totalExchanges}', Icons.swap_horiz),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 26, color: Theme.of(context).colorScheme.secondary),
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
              title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


class NearbyUsersSection extends StatelessWidget {
  final GeoPoint currentUserLocation;
  final String currentUserId;

  const NearbyUsersSection({super.key,
    required this.currentUserLocation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final _fs = FirestoreService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nearby Users', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        StreamBuilder<List<UserModel>>(
          stream: _fs.getNearbyUsers(currentUserLocation, currentUserId),
          builder: (context, snapshot) {
            final users = snapshot.data ?? [];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }

            if (users.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No nearby users found')));
            }

            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return SizedBox(
                    width: 130,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => NavigationHelper.navigateToUserProfile(context, user),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                backgroundImage: user.profileImageUrl != null
                                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                                    : null,
                                child: user.profileImageUrl == null
                                    ? Icon(Icons.person, size: 35, color: Theme.of(context).colorScheme.primary)
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Text(user.name, style: Theme.of(context).textTheme.titleSmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class SkillMatchesSection extends StatelessWidget {

  final List<String> currentUserSkillsToTeach;
  final List<String> currentUserSkillsToLearn;
  final String currentUserId; // To exclude current user from results

  const SkillMatchesSection({super.key,
    required this.currentUserSkillsToTeach,
    required this.currentUserSkillsToLearn,
    required this.currentUserId,});

  @override
  Widget build(BuildContext context) {
    final _fs = FirestoreService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skill Matches', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        StreamBuilder<List<UserModel>>(
          stream: _fs.getPotentialMatches(
              userSkillsToTeach: [],
              userSkillsToLearn: [],
              excludeUid: ''
          ),
          builder: (context, snapshot) {
            final matches = snapshot.data ?? [];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (matches.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No matches yet')));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: match.profileImageUrl != null
                          ? CachedNetworkImageProvider(match.profileImageUrl!)
                          : null,
                      child: match.profileImageUrl == null
                          ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    title: Text(match.name),
                    subtitle: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: match.skillsToTeach.take(5).map((skill) {
                        return Chip(
                          label: Text(skill, style: TextStyle(color:Theme.of(context).colorScheme.onSecondary, fontSize: 11)),
                          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                        );
                      }).toList(),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => NavigationHelper.navigateToUserProfile(context, match),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class RecentActivitiesSection extends StatelessWidget {
  const RecentActivitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final _fs = FirestoreService();
    return StreamBuilder<List<dynamic>>(
      stream: _fs.getRecentActivities(),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (activities.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No recent activity')));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(_getActivityTitle(activity)),
                subtitle: Text(_getActivitySubtitle(activity), maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  if (activity is NotificationModel) {
                    switch (activity.type) {
                      case NotificationType.exchangeRequest:
                      case NotificationType.exchangeAccepted:
                      case NotificationType.exchangeCompleted:
                        NavigationHelper.navigateToExchangeRequests(context);
                        break;
                      case NotificationType.newMessage:
                        if (activity.data['exchange'] != null && activity.data['otherUser'] != null) {
                          NavigationHelper.navigateToChat(
                            context,
                            activity.data['exchange'],
                            activity.data['otherUser'],
                          );
                        }
                        break;
                      case NotificationType.newReview:
                        if (activity.data['user'] != null) {
                          NavigationHelper.navigateToReviews(context, activity.data['user']);
                        }
                        break;
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  String _getActivityTitle(dynamic activity) {
    if (activity is NotificationModel) {
      switch (activity.type) {
        case NotificationType.exchangeRequest:
          return 'New Exchange Request';
        case NotificationType.exchangeAccepted:
          return 'Exchange Accepted';
        case NotificationType.exchangeCompleted:
          return 'Exchange Completed';
        case NotificationType.newMessage:
          return 'New Message';
        case NotificationType.newReview:
          return 'New Review';
      }
    }
    return 'Activity';
  }

  String _getActivitySubtitle(dynamic activity) {
    if (activity is NotificationModel) {
      return activity.message ?? '';
    }
    return activity.toString();
  }
}