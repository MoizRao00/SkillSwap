import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/activity_model.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: SizedBox());

    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color cardColor =
        Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header (same as Exchange Screen)
            Container(
              padding: const EdgeInsets.only(top: 5),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 8.0,
                shadowColor: Colors.black.withAlpha(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: cardColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title section
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Activity & Notifications',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                color: onSurfaceColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.white),

                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      indicatorColor: primaryColor,
                      labelColor: primaryColor,
                      unselectedLabelColor:
                      onSurfaceColor.withOpacity(0.6),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      unselectedLabelStyle: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.normal),
                      tabs: const [
                        Tab(text: 'Notifications'),
                        Tab(text: 'Activities'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NotificationsTab(userId: currentUser.uid, fs: _fs),
                  _ActivitiesTab(userId: currentUser.uid, fs: _fs),
                ],
              ),
            ),
          ],
        ),
      ),

      // Floating mark as all read
      floatingActionButton: StreamBuilder<List<NotificationModel>>(
        stream: _fs.getUserNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final unread = snapshot.data!.where((n) => n.isRead == false).toList();
          if (unread.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () async {
              await _fs.markAllNotificationsAsRead(currentUser.uid);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Marked ${unread.length} as read ✅'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            label: const Text("Mark All as Read"),
            icon: const Icon(Icons.done_all),
            backgroundColor: Theme.of(context).primaryColor,
          );
        },
      ),
    );
  }
}
class _NotificationsTab extends StatelessWidget {
  final String userId;
  final FirestoreService fs;

  const _NotificationsTab({
    required this.userId,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: fs.getUserNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see updates here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh will happen automatically due to StreamBuilder
          },
        child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationCard(
        key: ValueKey(notification.id + notification.isRead.toString()),
        notification: notification,
        fs: fs,
        );
    }
    )
        );
      },
    );
  }
}

class _ActivitiesTab extends StatelessWidget {
  final String userId;
  final FirestoreService fs;

  const _ActivitiesTab({
    required this.userId,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Activity>>(
      stream: fs.getUserActivities(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading activities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No activities yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your activity history will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh will happen automatically due to StreamBuilder
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _ActivityCard(activity: activity);
            },
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final FirestoreService fs;

  const _NotificationCard({
    super.key,
    required this.notification,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: notification.isRead ? 0 : 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: notification.isRead
          ? null
          : Theme.of(context).primaryColor.withOpacity(0.05),
      child: ListTile(
        leading: _getNotificationIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {
          // Handle notification tap
          fs.markNotificationAsRead(notification.id);
        },
      ),
    );
  }

  Widget _getNotificationIcon() {
    IconData iconData;
    Color color;

    switch (notification.type) {
      case NotificationType.exchangeRequest:
        iconData = Icons.swap_horiz;
        color = Colors.blue;
        break;
      case NotificationType.exchangeAccepted:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.exchangeCompleted:
        iconData = Icons.star;
        color = Colors.amber;
        break;
      case NotificationType.newMessage:
        iconData = Icons.message;
        color = Colors.purple;
        break;
      case NotificationType.newReview:
        iconData = Icons.rate_review;
        color = Colors.orange;
        break;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: _getActivityIcon(),
        title: Text(activity.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.description),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(activity.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getActivityIcon() {
    IconData iconData;
    Color color;

    switch (activity.type) {
      case ActivityType.exchangeRequest:
        iconData = Icons.swap_horiz;
        color = Colors.blue;
        break;
      case ActivityType.exchangeAccepted:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case ActivityType.exchangeCompleted:
        iconData = Icons.star;
        color = Colors.amber;
        break;
      case ActivityType.newReview:
        iconData = Icons.rate_review;
        color = Colors.orange;
        break;
      case ActivityType.skillAdded:
        iconData = Icons.add_circle;
        color = Colors.purple;
        break;
      case ActivityType.profileUpdate:
        iconData = Icons.person;
        color = Colors.blue;
        break;
      case ActivityType.exchangeDeclined:
        iconData = Icons.cancel;
        color = Colors.red;
        break;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inDays > 7) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  } else if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'Just now';
  }
}