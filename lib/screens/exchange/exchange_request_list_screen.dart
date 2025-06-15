// lib/screens/exchange/exchange_requests_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillswap/theme/app_theme.dart'; // Ensure this import is correct
import '../../models/exchange_request.dart';
import '../../services/firestore_service.dart';
import '../../widgets/animation/fade_animation.dart';
import '../../widgets/animation/slide_animation.dart';
import '../chat/chat_screen.dart';
import '../search/screen_search.dart';

class ExchangeRequestsListScreen extends StatefulWidget {
  const ExchangeRequestsListScreen({super.key});

  @override
  State<ExchangeRequestsListScreen> createState() =>
      _ExchangeRequestsListScreenState();
}

class _ExchangeRequestsListScreenState extends State<ExchangeRequestsListScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  late TabController _tabController;
  // We will get current user from FirebaseAuth.instance.currentUser directly in build.
  // No need for a _currentUser state variable if only used for UID.


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

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view exchanges')),
      );
    }

    // Access theme colors for consistency
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color onSecondaryColor = Theme.of(context).colorScheme.onSecondary;
    final Color cardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;
    return Scaffold(
      body: Column(
        children: [

          Container(

            padding: const EdgeInsets.only(top: 5),// L,T,R,B
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 8.0,
              shadowColor: Colors.black.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cardColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title section
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Skill Exchanges',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: onSurfaceColor, // Text color on the card surface
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.white), // Visual separator

                  // TabBar Section
                  TabBar(
                    controller: _tabController,
                    indicatorColor: primaryColor, // Indicator line below the selected tab
                    labelColor: primaryColor, // Color for selected tab's icon/text
                    unselectedLabelColor: onSurfaceColor.withOpacity(0.7), // Muted color for unselected tabs
                    indicatorSize: TabBarIndicatorSize.tab, // Indicator covers the whole tab

                    // Font styles for tabs
                    labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold, // Make selected tab text bold
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.normal, // Normal weight for unselected
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        // Removed 'const' for dynamic theming
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, color: _tabController.index == 0 ? primaryColor : onSurfaceColor.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            Text('Received', style: TextStyle(color: _tabController.index == 0 ? primaryColor : onSurfaceColor.withOpacity(0.7))),
                            StreamBuilder<List<ExchangeRequest>>(
                              stream: _fs.getExchangeRequests(
                                userId: currentUser.uid,
                                isReceived: true,
                              ),
                              builder: (context, snapshot) {
                                final pendingCount =
                                    snapshot.data
                                        ?.where((r) => r.status == ExchangeStatus.pending)
                                        .length ??
                                        0;
                                if (pendingCount == 0) return const SizedBox();
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: secondaryColor, // Use secondary color for badge
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    pendingCount.toString(),
                                    style: TextStyle(
                                      color: onSecondaryColor, // Text color on secondary background
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        // Removed 'const' for dynamic theming
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.outbox, color: _tabController.index == 1 ? primaryColor : onSurfaceColor.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            Text('Sent', style: TextStyle(color: _tabController.index == 1 ? primaryColor : onSurfaceColor.withOpacity(0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // TabBarView takes the remaining space
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RequestsList(
                  userId: currentUser.uid,
                  isReceived: true,
                  firestoreService: _fs,
                ),
                _RequestsList(
                  userId: currentUser.uid,
                  isReceived: false,
                  firestoreService: _fs,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FadeAnimation(
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('New Exchange'),
        ),
      ),
    );
  }
}

// _RequestsList and _ExchangeRequestCard classes remain unchanged from your provided code
// You might want to update _ExchangeRequestCard to use theme colors for its status display (Colors.orange, green etc.)
// For example:
// Color _getStatusColor(BuildContext context) {
//   switch (request.status) {
//     case ExchangeStatus.pending: return Theme.of(context).colorScheme.tertiary; // Use a distinct color
//     case ExchangeStatus.accepted: return Theme.of(context).colorScheme.primary;
//     case ExchangeStatus.completed: return Theme.of(context).colorScheme.secondary;
//     case ExchangeStatus.declined:
//     case ExchangeStatus.cancelled: return Theme.of(context).colorScheme.error;
//   }
// }


class _RequestsList extends StatefulWidget {
  final String userId;
  final bool isReceived;
  final FirestoreService firestoreService;

  const _RequestsList({
    required this.userId,
    required this.isReceived,
    required this.firestoreService,
  });

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExchangeRequest>>(
      stream: widget.firestoreService.getExchangeRequests(
        userId: widget.userId,
        isReceived: widget.isReceived,
      ),
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
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return FadeAnimation(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isReceived ? Icons.inbox : Icons.outbox,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.isReceived ? 'received' : 'sent'} requests',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isReceived
                        ? 'When someone requests to exchange skills with you,\nthey will appear here'
                        : 'When you send skill exchange requests,\nthey will appear here',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return SlideAnimation(
              direction: SlideDirection.fromRight,
              delay: Duration(milliseconds: index * 100),
              child: _ExchangeRequestCard(
                request: request,
                isReceived: widget.isReceived,
                firestoreService: widget.firestoreService,
              ),
            );
          },
        );
      },
    );
  }
}

class _ExchangeRequestCard extends StatelessWidget {
  final ExchangeRequest request;
  final bool isReceived;
  final FirestoreService firestoreService;

  const _ExchangeRequestCard({
    required this.request,
    required this.isReceived,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    // Access theme colors in build method for use in sub-widgets
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color tertiaryColor = Theme.of(context).colorScheme.tertiary ?? Colors.orange; // Fallback for tertiary
    final Color errorColor = Theme.of(context).colorScheme.error;


    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      // Card properties are typically handled by CardThemeData in app_theme.dart
      // If you need specific overrides, you can apply them here.
      child: InkWell(
        onTap: () async {
          if (request.status == ExchangeStatus.accepted) {
            final otherUser = await firestoreService.getUser(
              isReceived ? request.senderId : request.receiverId,
            );
            if (otherUser != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(exchange: request, otherUser: otherUser),
                ),
              );
            }
          }
        },
        child: Column(
          children: [
            _buildHeader(context),
            _buildBody(context),
            if (request.status == ExchangeStatus.pending && isReceived)
              _buildActions(context),
            if (request.status == ExchangeStatus.accepted)
              _buildChatButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton(BuildContext context) {
    // Use theme colors for buttons
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                TextButton(
                  onPressed: () async {
                    await firestoreService.updateExchangeStatus(
                      request.id,
                      ExchangeStatus.cancelled,
                    );
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Theme.of(context).colorScheme.error), // Use error color for cancel
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await firestoreService.updateExchangeStatus(
                      request.id,
                      ExchangeStatus.completed,
                    );
                  },
                  // Button style will come from ElevatedButtonThemeData in AppTheme
                  child: const Text('Complete'),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('Chat'),
            // Button style will come from ElevatedButtonThemeData in AppTheme
            // If you want a specific color just for chat, override it here
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              final otherUser = await firestoreService.getUser(
                isReceived ? request.senderId : request.receiverId,
              );
              if (otherUser != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(exchange: request, otherUser: otherUser),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Use theme colors for status header
    final Color statusColor = _getStatusColor(context);
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), // Retain top rounded corners for card
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: statusColor),
          const SizedBox(width: 8),
          Text(
            request.status.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            _formatDate(request.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onSurfaceColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Use onSurface color for general text on card body
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReceived ? 'They\'ll teach:' : 'You\'ll teach:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onSurfaceColor.withOpacity(0.7)),
                    ),
                    Text(
                      request.senderSkill,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: onSurfaceColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.swap_horiz, color: onSurfaceColor.withOpacity(0.7)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isReceived ? 'You\'ll teach:' : 'They\'ll teach:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onSurfaceColor.withOpacity(0.7)),
                    ),
                    Text(
                      request.receiverSkill,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: onSurfaceColor),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Message:', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: onSurfaceColor.withOpacity(0.8))),
            const SizedBox(height: 4),
            Text(request.message, style: TextStyle(color: onSurfaceColor)),
          ],
          if (request.location != null || request.scheduledDate != null) ...[
            const SizedBox(height: 16),
            if (request.location != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: onSurfaceColor.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(request.location!, style: TextStyle(color: onSurfaceColor)),
                ],
              ),
            if (request.scheduledDate != null)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: onSurfaceColor.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(_formatDate(request.scheduledDate!), style: TextStyle(color: onSurfaceColor)),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () async {
              await firestoreService.updateExchangeStatus(
                request.id,
                ExchangeStatus.declined,
              );
            },
            child: Text(
              'Decline',
              style: TextStyle(color: Theme.of(context).colorScheme.error), // Use error color for decline
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await firestoreService.updateExchangeStatus(
                request.id,
                ExchangeStatus.accepted,
              );
            },
            // Button style will come from ElevatedButtonThemeData in AppTheme
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  // Modified to accept BuildContext to use theme colors
  Color _getStatusColor(BuildContext context) {
    switch (request.status) {
      case ExchangeStatus.pending:
        return Theme.of(context).colorScheme.tertiary ?? Colors.orange; // Use tertiary if defined, else orange
      case ExchangeStatus.accepted:
        return Theme.of(context).colorScheme.primary;
      case ExchangeStatus.completed:
        return Theme.of(context).colorScheme.secondary;
      case ExchangeStatus.declined:
      case ExchangeStatus.cancelled:
        return Theme.of(context).colorScheme.error;
    }
  }

  IconData _getStatusIcon() {
    switch (request.status) {
      case ExchangeStatus.pending:
        return Icons.schedule;
      case ExchangeStatus.accepted:
        return Icons.check_circle;
      case ExchangeStatus.completed:
        return Icons.star;
      case ExchangeStatus.declined:
      case ExchangeStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
