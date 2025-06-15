import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/usermodel.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/navigation_helper.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: const [
            RepaintBoundary(child: WelcomeCard()),
            SizedBox(height: 24),
            RepaintBoundary(child: StatsOverview()),
            SizedBox(height: 32),
            RepaintBoundary(child: NearbyUsersSection()),
            SizedBox(height: 32),
            RepaintBoundary(child: SkillMatchesSection()),
            SizedBox(height: 32),
            RepaintBoundary(child: RecentActivitiesSection()),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Welcome Card
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final _fs = FirestoreService();
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  backgroundImage: user?.profilePicUrl != null
                      ? CachedNetworkImageProvider(user!.profilePicUrl!)
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
                      Text('Welcome back,', style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        user?.name ?? 'User',
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
      },
    );
  }
}

// Stats Overview
class StatsOverview extends StatelessWidget {
  const StatsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final _fs = FirestoreService();
    return StreamBuilder<UserModel?>(
      stream: _fs.getUserStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatTile(context, 'Skills Teaching', '${user?.skillsToTeach.length ?? 0}', Icons.school),
                _buildStatTile(context, 'Skills Learning', '${user?.skillsToLearn.length ?? 0}', Icons.psychology),
                _buildStatTile(context, 'Exchanges', '${user?.totalExchanges ?? 0}', Icons.swap_horiz),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatTile(BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
class NearbyUsersSection extends StatelessWidget {
  const NearbyUsersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final _fs = FirestoreService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nearby Users', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        StreamBuilder<List<UserModel>>(
          stream: _fs.getNearbyUsers(),
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
                                backgroundImage: user.profilePicUrl != null
                                    ? CachedNetworkImageProvider(user.profilePicUrl!)
                                    : null,
                                child: user.profilePicUrl == null
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
  const SkillMatchesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final _fs = FirestoreService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skill Matches', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        StreamBuilder<List<UserModel>>(
          stream: _fs.getPotentialMatches(),
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
                      backgroundImage: match.profilePicUrl != null
                          ? CachedNetworkImageProvider(match.profilePicUrl!)
                          : null,
                      child: match.profilePicUrl == null
                          ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    title: Text(match.name),
                    subtitle: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: match.skillsToTeach.take(5).map((skill) {
                        return Chip(
                          label: Text(skill, style: TextStyle(color: Colors.white, fontSize: 11)),
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