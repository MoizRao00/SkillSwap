import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification_model.dart';
import '../../models/usermodel.dart';
import '../../services/firestore_service.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/animation/fade_animation.dart';
import '../../widgets/animation/slide_animation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // Refreshes the StreamBuilders
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Welcome Card with slide and fade animation
            SlideAnimation(
              direction: SlideDirection.fromTop,
              child: FadeAnimation(child: _buildWelcomeCard(context)),
            ),
            const SizedBox(height: 24),

            // Stats Overview with staggered animations - MODIFIED BELOW
            _buildStatsOverview(context),
            const SizedBox(height: 32),

            // Nearby Users with slide animation
            SlideAnimation(
              direction: SlideDirection.fromRight,
              delay: const Duration(milliseconds: 300),
              child: _buildSection(
                context: context,
                title: 'Nearby Users',
                child: _buildNearbyUsers(context),
              ),
            ),
            const SizedBox(height: 32),

            // Skill Matches with slide animation
            SlideAnimation(
              direction: SlideDirection.fromLeft,
              delay: const Duration(milliseconds: 400),
              child: _buildSection(
                context: context,
                title: 'Potential Skill Matches',
                child: _buildSkillMatches(context),
              ),
            ),
            const SizedBox(height: 32),

            // Recent Activities with fade animation
            FadeAnimation(
              delay: const Duration(milliseconds: 500),
              child: _buildSection(
                context: context,
                title: 'Recent Activities',
                child: _buildRecentActivities(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _fs.getUserStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      backgroundImage: user?.profilePicUrl != null
                          ? NetworkImage(user!.profilePicUrl!)
                          : null,
                      child: user?.profilePicUrl == null
                          ? Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            user?.name ?? 'User',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // MODIFIED _buildStatsOverview method
  Widget _buildStatsOverview(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _fs.getUserStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Card(
          elevation: 6, // Slightly less elevation than welcome card, but still lifted
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners for the outer card
          margin: EdgeInsets.zero, // Remove default card margin
          shadowColor: Colors.black.withOpacity(0.2), // Subtle shadow
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0), // Adjusted padding for the outer card
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute space
              children: [
                Expanded(
                  child: SlideAnimation(
                    direction: SlideDirection.fromLeft,
                    delay: const Duration(milliseconds: 400),
                    child: _buildStatCard(
                      context,
                      'Skills Teaching',
                      '${user?.skillsToTeach.length ?? 0}',
                      Icons.school,
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Reduced space between cards
                Expanded(
                  child: SlideAnimation(
                    direction: SlideDirection.fromBottom,
                    delay: const Duration(milliseconds: 300),
                    child: _buildStatCard(
                      context,
                      'Skills Learning',
                      '${user?.skillsToLearn.length ?? 0}',
                      Icons.psychology,
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Reduced space between cards
                Expanded(
                  child: SlideAnimation(
                    direction: SlideDirection.fromRight,
                    delay: const Duration(milliseconds: 400),
                    child: _buildStatCard(
                      context,
                      'Exchanges',
                      '${user?.totalExchanges ?? 0}',
                      Icons.swap_horiz,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // MODIFIED _buildStatCard method
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
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
              icon,
              color: Theme.of(context).colorScheme.secondary,
              size: 28, // Slightly reduced icon size to fit better
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
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 12, // Adjusted font size for title
              ),
              textAlign: TextAlign.center,
              maxLines: 1, // Crucial: Ensures title is on one line
              overflow: TextOverflow.ellipsis, // Truncates if it's too long
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required BuildContext context, required String title, required Widget child}) {
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
        const SizedBox(height: 18),
        child,
      ],
    );
  }

  Widget _buildNearbyUsers(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _fs.getNearbyUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return FadeAnimation(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No nearby users found')),
              ),
            ),
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return SlideAnimation(
                direction: SlideDirection.fromBottom,
                delay: Duration(milliseconds: 200 * index),
                child: SizedBox(
                  width: 130,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => NavigationHelper.navigateToUserProfile(context, user),
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              backgroundImage: user.profilePicUrl != null
                                  ? NetworkImage(user.profilePicUrl!)
                                  : null,
                              child: user.profilePicUrl == null
                                  ? Icon(Icons.person, size: 35, color: Theme.of(context).colorScheme.primary)
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.location ?? 'No location',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkillMatches(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _fs.getPotentialMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No skill matches found')),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return SlideAnimation(
              direction: SlideDirection.fromRight,
              delay: Duration(milliseconds: 200 * index),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: match.profilePicUrl != null
                        ? NetworkImage(match.profilePicUrl!)
                        : null,
                    child: match.profilePicUrl == null
                        ? Icon(Icons.person, size: 30, color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  title: Text(
                    match.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: match.skillsToTeach
                        .take(3)
                        .map(
                          (skill) => Chip(
                        label: Text(
                          skill,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    )
                        .toList(),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
                  onTap: () => NavigationHelper.navigateToUserProfile(context, match),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: _fs.getRecentActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No recent activities')),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return FadeAnimation(
              delay: Duration(milliseconds: 200 * index),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Icon(
                    Icons.notifications,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 30,
                  ),
                  title: Text(
                    _getActivityTitle(activity),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _getActivitySubtitle(activity),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
                  onTap: () {
                    if (activity is NotificationModel) {
                      switch (activity.type) {
                        case NotificationType.exchangeRequest:
                        case NotificationType.exchangeAccepted:
                        case NotificationType.exchangeCompleted:
                          NavigationHelper.navigateToExchangeRequests(context);
                          break;
                        case NotificationType.newMessage:
                          if (activity.data['exchangeId'] != null && activity.data['otherUser'] != null) {
                            NavigationHelper.navigateToChat(
                              context,
                              activity.data['exchange'],
                              activity.data['otherUser'],
                            );
                          }
                          break;
                        case NotificationType.newReview:
                          if (activity.data['userId'] != null) {
                            NavigationHelper.navigateToReviews(
                              context,
                              activity.data['user'],
                            );
                          }
                          break;
                      }
                    }
                  },
                ),
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
        case NotificationType.exchangeRequest: return 'New Exchange Request';
        case NotificationType.exchangeAccepted: return 'Exchange Accepted!';
        case NotificationType.exchangeCompleted: return 'Exchange Completed';
        case NotificationType.newMessage: return 'New Message';
        case NotificationType.newReview: return 'New Review';
        default: return 'New Activity';
      }
    }
    return 'New Activity';
  }

  String _getActivitySubtitle(dynamic activity) {
    if (activity is NotificationModel) {
      if (activity.type == NotificationType.newMessage && activity.data['otherUser'] != null) {
        return 'From ${activity.data['otherUser'].name ?? 'someone'}';
      }
      return activity.message ?? '';
    }
    return activity.toString();
  }
}