// lib/screens/exchange/exchange_requests_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/exchange_request.dart';
import '../../services/firestore_service.dart';
import '../../models/usermodel.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Exchanges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox),
                  const SizedBox(width: 8),
                  const Text('Received'),
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
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          pendingCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.outbox),
                  SizedBox(width: 8),
                  Text('Sent'),
                ],
              ),
            ),
          ],
        ),
      ),

      body: TabBarView(
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
      floatingActionButton: FadeAnimation(
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('New Exchange'),
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isReceived
                        ? 'When someone requests to exchange skills with you,\nthey will appear here'
                        : 'When you send skill exchange requests,\nthey will appear here',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
            if (request.status == ExchangeStatus.accepted)  // Add this line
              _buildChatButton(context),                    // Add this line
          ],
        ),
      ),
    );
  }
  Widget _buildChatButton(BuildContext context) {
    if (request.status == ExchangeStatus.accepted) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                backgroundColor: Theme.of(context).primaryColor,
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
    return const SizedBox.shrink();
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: _getStatusColor()),
          const SizedBox(width: 8),
          Text(
            request.status.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            _formatDate(request.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
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
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Message:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(request.message),
          ],
          if (request.location != null || request.scheduledDate != null) ...[
            const SizedBox(height: 16),
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
      ),
    );
  }

  Color _getStatusColor() {
    switch (request.status) {
      case ExchangeStatus.pending:
        return Colors.orange;
      case ExchangeStatus.accepted:
        return Colors.green;
      case ExchangeStatus.completed:
        return Colors.blue;
      case ExchangeStatus.declined:
      case ExchangeStatus.cancelled:
        return Colors.red;
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
