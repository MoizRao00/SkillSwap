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
      body:
      RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card with slide and fade animation
            SlideAnimation(
              direction: SlideDirection.fromTop,
              child: FadeAnimation(child: _buildWelcomeCard()),
            ),
            const SizedBox(height: 16),

            // Stats Overview with staggered animations
            _buildStatsOverview(),
            const SizedBox(height: 24),

            // Nearby Users with slide animation
            SlideAnimation(
              direction: SlideDirection.fromRight,
              delay: const Duration(milliseconds: 300),
              child: _buildSection(
                title: 'Nearby Users',
                child: _buildNearbyUsers(),
              ),
            ),
            const SizedBox(height: 24),

            // Skill Matches with slide animation
            SlideAnimation(
              direction: SlideDirection.fromLeft,
              delay: const Duration(milliseconds: 400),
              child: _buildSection(
                title: 'Potential Skill Matches',
                child: _buildSkillMatches(),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Activities with fade animation
            FadeAnimation(
              delay: const Duration(milliseconds: 500),
              child: _buildSection(
                title: 'Recent Activities',
                child: _buildRecentActivities(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return StreamBuilder<UserModel?>(
      stream: _fs.getUserStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: user?.profilePicUrl != null
                          ? NetworkImage(user!.profilePicUrl!)
                          : null,
                      child: user?.profilePicUrl == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            user?.name ?? 'User',
                            style: Theme.of(context).textTheme.headlineSmall,
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

  Widget _buildStatsOverview() {
    return StreamBuilder<UserModel?>(
      stream: _fs.getUserStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Row(
          children: [
            Expanded(
              child: SlideAnimation(
                direction: SlideDirection.fromLeft,
                delay: const Duration(milliseconds: 200),
                child: _buildStatCard(
                  'Skills Teaching',
                  '${user?.skillsToTeach.length ?? 0}',
                  Icons.school,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SlideAnimation(
                direction: SlideDirection.fromBottom,
                delay: const Duration(milliseconds: 300),
                child: _buildStatCard(
                  'Skills Learning',
                  '${user?.skillsToLearn.length ?? 0}',
                  Icons.psychology,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SlideAnimation(
                direction: SlideDirection.fromRight,
                delay: const Duration(milliseconds: 400),
                child: _buildStatCard(
                  'Exchanges',
                  '${user?.totalExchanges ?? 0}',
                  Icons.swap_horiz,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildNearbyUsers() {
    return StreamBuilder<List<UserModel>>(
      stream: _fs.getNearbyUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return FadeAnimation(
            child: const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No nearby users found'),
              ),
            ),
          );
        }

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return SlideAnimation(
                direction: SlideDirection.fromBottom,
                delay: Duration(milliseconds: 200 * index),
                child: SizedBox(
                  width: 120,
                  child: Card(
                    child: InkWell(
                      onTap: () => NavigationHelper.navigateToUserProfile(context, user),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: user.profilePicUrl != null
                                  ? NetworkImage(user.profilePicUrl!)
                                  : null,
                              child: user.profilePicUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.location ?? 'No location',
                              style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildSkillMatches() {
    return StreamBuilder<List<UserModel>>(
      stream: _fs.getPotentialMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No skill matches found'),
            ),
          );
        }

        return ListView.builder(
          itemBuilder: (context, index) {
            final match = matches[index];
            return SlideAnimation(
              direction: SlideDirection.fromRight,
              delay: Duration(milliseconds: 200 * index),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: match.profilePicUrl != null
                        ? NetworkImage(match.profilePicUrl!)
                        : null,
                    child: match.profilePicUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(match.name),
                  subtitle: Wrap(
                    spacing: 4,
                    children: match.skillsToTeach
                        .take(2)
                        .map(
                          (skill) => Chip(
                            label: Text(
                              skill,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => NavigationHelper.navigateToUserProfile(context, match),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivities() {
    return StreamBuilder<List<dynamic>>(
      stream: _fs.getRecentActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No recent activities'),
            ),
          );
        }

        return ListView.builder(
          itemBuilder: (context, index) {
            final activity = activities[index];
            return FadeAnimation(
              delay: Duration(milliseconds: 200 * index),
              child: Card(
                child: ListTile(
                  // Customize based on activity type
                  leading: const Icon(Icons.notifications),
                  title: const Text('New Activity'),
                  subtitle: Text(activity.toString()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
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
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
