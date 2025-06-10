// lib/screens/exchange/exchange_requests_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/exchange_request.dart';
import '../../services/firestore_service.dart';
import '../../models/usermodel.dart';
import '../chat/chat_screen.dart';
import '../review/review_screen.dart';

class ExchangeRequestsListScreen extends StatefulWidget {
  const ExchangeRequestsListScreen({super.key});

  @override
  State<ExchangeRequestsListScreen> createState() => _ExchangeRequestsListScreenState();
}

class _ExchangeRequestsListScreenState extends State<ExchangeRequestsListScreen> {
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view exchanges')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Skill Exchanges'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Received Requests Tab
            _RequestsList(
              userId: currentUser.uid,
              isReceived: true,
              firestoreService: _fs,
            ),
            // Sent Requests Tab
            _RequestsList(
              userId: currentUser.uid,
              isReceived: false,
              firestoreService: _fs,
            ),
          ],
        ),
      ),
    );
  }
}

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
                  onPressed: () {
                    setState(() {}); // Now setState is available
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isReceived ? Icons.inbox : Icons.outbox,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${widget.isReceived ? 'received' : 'sent'} requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isReceived
                      ? 'When someone requests to exchange skills with you,\nthey will appear here'
                      : 'When you send skill exchange requests,\nthey will appear here',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _ExchangeRequestCard(
              request: request,
              isReceived: widget.isReceived,
              firestoreService: widget.firestoreService,
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

  Future<bool> _hasUserReviewed(String exchangeId, String userId) async {
    try {
      final reviews = await firestoreService.getExchangeReviews(exchangeId);
      return reviews.any((review) => review.reviewerId == userId);
    } catch (e) {
      print('❌ Error checking review status: $e');
      return false;
    }
  }

  void _openChat(BuildContext context, UserModel otherUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          exchange: request,
          otherUser: otherUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      // Check if user has reviewed when exchange is completed
        future: request.status == ExchangeStatus.completed
            ? _hasUserReviewed(
          request.id,
          FirebaseAuth.instance.currentUser?.uid ?? '',
        )
            : Future.value(false),
        builder: (context, snapshot) {
          final hasReviewed = snapshot.data ?? false;
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Date Row
                  Row(
                    children: [
                      _buildStatusChip(),
                      const Spacer(),
                      Text(
                        _formatDate(request.createdAt),
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                  const Divider(),

                  // Skills Exchange Section
                  _buildSkillsExchange(context),
                  const SizedBox(height: 16),

                  // Message Section
                  if (request.message.isNotEmpty) ...[
                    Text(
                      'Message:',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(request.message),
                    const SizedBox(height: 16),
                  ],

                  // Details Section
                  if (request.location != null || request.scheduledDate != null)
                    _buildDetailsSection(context),

                  // Pending Request Buttons
                  if (request.status == ExchangeStatus.pending &&
                      isReceived) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await firestoreService.updateExchangeStatus(
                              request.id,
                              ExchangeStatus.declined,
                            );
                          },
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await firestoreService.updateExchangeStatus(
                              request.id,
                              ExchangeStatus.accepted,
                            );
                          },
                          child: const Text('Accept'),
                        ),
                        if (request.status == ExchangeStatus.completed &&
                            !hasReviewed) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.star),
                            label: const Text('Write Review'),
                            onPressed: () async {
                              final otherUserId = isReceived
                                  ? request.senderId
                                  : request.receiverId;
                              final otherUser = await firestoreService.getUser(
                                  otherUserId);
                              if (otherUser != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReviewScreen(
                                          exchange: request,
                                          otherUser: otherUser,
                                        ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ],

                    ),
                  ],

                  // Accepted Request Buttons (Chat, Complete, Cancel)
                  if (request.status == ExchangeStatus.accepted) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Complete/Cancel buttons
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
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  await firestoreService.updateExchangeStatus(
                                    request.id,
                                    ExchangeStatus.completed,
                                  );
                                },
                                child: const Text('Complete'),
                              ),
                            ],
                          ),
                        ),
                        // Chat button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme
                                .of(context)
                                .primaryColor,
                          ),
                          onPressed: () async {
                            // Get the other user's data
                            final otherUserId = isReceived
                                ? request.senderId
                                : request.receiverId;
                            final otherUser = await firestoreService.getUser(
                                otherUserId);
                            if (otherUser != null && context.mounted) {
                              _openChat(context, otherUser);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }
    );

  }
  Widget _buildStatusChip() {
    Color chipColor;
    IconData iconData;

    switch (request.status) {
      case ExchangeStatus.pending:
        chipColor = Colors.orange;
        iconData = Icons.schedule;
        break;
      case ExchangeStatus.accepted:
        chipColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case ExchangeStatus.completed:
        chipColor = Colors.blue;
        iconData = Icons.star;
        break;
      case ExchangeStatus.declined:
      case ExchangeStatus.cancelled:
        chipColor = Colors.red;
        iconData = Icons.cancel;
        break;
    }

    return Chip(
      avatar: Icon(iconData, size: 16, color: chipColor),
      label: Text(
        request.status.toString().split('.').last.toUpperCase(),
        style: TextStyle(color: chipColor),
      ),
      backgroundColor: chipColor.withOpacity(0.1),
    );
  }

  Widget _buildSkillsExchange(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isReceived ? 'They\'ll teach:' : 'You\'ll teach:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                request.senderSkill,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const Icon(Icons.swap_horiz),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isReceived ? 'You\'ll teach:' : 'They\'ll teach:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                request.receiverSkill,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (request.location != null)
          Row(
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 4),
              Text(request.location!),
            ],
          ),
        if (request.scheduledDate != null)
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 4),
              Text(_formatDate(request.scheduledDate!)),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (!isReceived || request.status != ExchangeStatus.pending) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () async {
            await firestoreService.updateExchangeStatus(
              request.id,
              ExchangeStatus.declined,
            );
          },
          child: const Text('Decline'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            await firestoreService.updateExchangeStatus(
              request.id,
              ExchangeStatus.accepted,

            );
          },
          child: const Text('Accept'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}