import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/animation/fade_animation.dart';
import '../../widgets/animation/slide_animation.dart';

class NotificationsScreen extends StatelessWidget {
  final FirestoreService _fs = FirestoreService();

  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar:
      AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: _fs.getUserNotifications(currentUser.uid),
            builder: (context, snapshot) {
              final hasUnread = snapshot.data?.any((n) => !n.isRead) ?? false;
              if (!hasUnread) return const SizedBox();

              return TextButton.icon(
                icon: const Icon(Icons.done_all),
                label: const Text('Mark all read'),
                onPressed: () {
                  _fs.markAllNotificationsAsRead(currentUser.uid);
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _fs.getUserNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger rebuild
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return FadeAnimation(
              child: Center(
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
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You\'ll see your notifications here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group notifications by date
          final groupedNotifications = _groupNotificationsByDate(notifications);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groupedNotifications.length,
            itemBuilder: (context, index) {
              final date = groupedNotifications.keys.elementAt(index);
              final notificationsForDate = groupedNotifications[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      _formatDate(date),
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...notificationsForDate.map((notification) {
                    return SlideAnimation(
                      direction: SlideDirection.fromRight,
                      child: _NotificationCard(
                        notification: notification,
                        onTap: () =>
                            _handleNotificationTap(
                              context,
                              notification,
                            ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<NotificationModel>> _groupNotificationsByDate(
      List<NotificationModel> notifications,) {
    final grouped = <DateTime, List<NotificationModel>>{};

    for (var notification in notifications) {
      final date = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(notification);
    }

    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleNotificationTap(BuildContext context,
      NotificationModel notification) {
    // Mark as read
    _fs.markNotificationAsRead(notification.id);

    // Navigate based on type
    switch (notification.type) {
      case NotificationType.exchangeRequest:
      case NotificationType.exchangeAccepted:
      case NotificationType.exchangeCompleted:
        if (notification.data['exchangeId'] != null) {
          NavigationHelper.navigateToExchangeRequests(context);
        }
        break;
      case NotificationType.newMessage:
        if (notification.data['exchangeId'] != null &&
            notification.data['otherUser'] != null) {
          NavigationHelper.navigateToChat(
            context,
            notification.data['exchange'],
            notification.data['otherUser'],
          );
        }
        break;
      case NotificationType.newReview:
        if (notification.data['userId'] != null) {
          NavigationHelper.navigateToReviews(
            context,
            notification.data['user'],
          );
        }
        break;
    }
  }
  
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: notification.isRead
          ? null
          : Theme.of(context).primaryColor.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight:
                        notification.isRead ? null : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
