import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/exchange_request.dart';
import '../../models/chat_message.dart';
import '../../models/usermodel.dart'; // Make sure this is the correct model for your UserProfile
import '../../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final ExchangeRequest exchange;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.exchange,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final FirestoreService _fs = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showReviewDialog(BuildContext context, String exchangeId, String otherUserId) {
    final _reviewController = TextEditingController();
    int _selectedRating = 5; // Default rating

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Leave a Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reviewController,
                    decoration: const InputDecoration(
                      labelText: 'Write your review (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _fs.submitReview(
                      exchangeId: exchangeId,
                      reviewedUserId: otherUserId,
                      rating: _selectedRating.toDouble(),
                      comment: _reviewController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review submitted!')),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(ExchangeStatus status) {
    switch (status) {
      case ExchangeStatus.pending:
        return Colors.orange;
      case ExchangeStatus.accepted:
        return Colors.green;
      case ExchangeStatus.completed:
        return Colors.blue;
      case ExchangeStatus.declined:
      case ExchangeStatus.cancelled:
        return Colors.red;
      case ExchangeStatus.confirmedBySender:
      case ExchangeStatus.confirmedByReceiver:
        return Colors.blueGrey;
    }
  }

  IconData _getStatusIcon(ExchangeStatus status) {
    switch (status) {
      case ExchangeStatus.pending:
        return Icons.schedule;
      case ExchangeStatus.accepted:
        return Icons.check_circle;
      case ExchangeStatus.completed:
        return Icons.star;
      case ExchangeStatus.declined:
      case ExchangeStatus.cancelled:
        return Icons.cancel;
      case ExchangeStatus.confirmedBySender:
      case ExchangeStatus.confirmedByReceiver:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusText(ExchangeStatus status) {
    final currentUserId = _currentUser?.uid;
    final isSender = currentUserId == widget.exchange.senderId;

    switch (status) {
      case ExchangeStatus.pending:
        return 'Exchange request is pending';
      case ExchangeStatus.accepted:
        return 'Exchange is active';
      case ExchangeStatus.confirmedBySender:
        if (isSender) {
          return 'You have marked as complete. Awaiting confirmation from the other person.';
        } else {
          return 'The other person has marked as complete. Please confirm to finish.';
        }
      case ExchangeStatus.confirmedByReceiver:
        if (isSender) {
          return 'The other person has marked as complete. Please confirm to finish.';
        } else {
          return 'You have marked as complete. Awaiting confirmation from the other person.';
        }
      case ExchangeStatus.completed:
        return 'Exchange completed';
      case ExchangeStatus.declined:
        return 'Exchange declined';
      case ExchangeStatus.cancelled:
        return 'Exchange cancelled';
    }
  }

  Widget _buildActionButtons(ExchangeRequest exchange) {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    final status = exchange.status;
    final isSender = currentUserId == exchange.senderId;
    final isReceiver = currentUserId == exchange.receiverId;

    if (status == ExchangeStatus.declined || status == ExchangeStatus.cancelled) {
      return const SizedBox.shrink();
    }

    if (status == ExchangeStatus.pending && isReceiver) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _fs.updateExchangeStatus(exchange.id, ExchangeStatus.accepted),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Accept Exchange'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _fs.updateExchangeStatus(exchange.id, ExchangeStatus.declined),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Decline'),
            ),
          ),
        ],
      );
    }

    if (status == ExchangeStatus.accepted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            final newStatus = isSender ? ExchangeStatus.confirmedBySender : ExchangeStatus.confirmedByReceiver;
            _fs.updateExchangeStatus(exchange.id, newStatus);
          },
          icon: const Icon(Icons.done_all),
          label: const Text('Mark as Completed'),
        ),
      );
    }

    if (status == ExchangeStatus.confirmedBySender || status == ExchangeStatus.confirmedByReceiver) {
      final hasConfirmed = (status == ExchangeStatus.confirmedBySender && isSender) || (status == ExchangeStatus.confirmedByReceiver && isReceiver);

      if (hasConfirmed) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'You have confirmed completion. Waiting for the other person to confirm.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _fs.updateExchangeStatus(exchange.id, ExchangeStatus.completed),
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirm Completion'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        );
      }
    }

    if (status == ExchangeStatus.completed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showReviewDialog(context, exchange.id, widget.otherUser.uid),
          icon: const Icon(Icons.rate_review),
          label: const Text('Leave a Review'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exchange'),
        content: const Text('Are you sure you want to delete this exchange? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _fs.deleteExchange(widget.exchange.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exchange deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting exchange: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;


    setState(() {
      _isSending = true;
      _messageController.clear();
    });

    try {

      await _fs.sendMessage(
        widget.exchange.id,
        message,
      );



      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.position.pixels;
          if ((maxScroll - currentScroll).abs() < 100) {
            _scrollController.animateTo(
              _scrollController.position.minScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      });

    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showExchangeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExchangeDetailsSheet(exchange: widget.exchange, otherUser: widget.otherUser),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  /// ⭐ REFACTORED: Use two separate StreamBuilders to prevent unnecessary rebuilds.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: widget.otherUser.profileImageUrl != null
                ? NetworkImage(widget.otherUser.profileImageUrl!)
                : null,
            child: widget.otherUser.profileImageUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
            widget.otherUser.name,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            '${widget.exchange.senderSkill} ↔ ${widget.exchange.receiverSkill}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showExchangeDetails(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteConfirmationDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. This StreamBuilder handles the exchange status and action buttons.
            StreamBuilder<ExchangeRequest>(
              stream: _fs.getExchangeStream(widget.exchange.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }

                final updatedExchange = snapshot.data!;

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: _getStatusColor(updatedExchange.status).withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(updatedExchange.status),
                            size: 16,
                            color: _getStatusColor(updatedExchange.status),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getStatusText(updatedExchange.status),
                              style: TextStyle(
                                color: _getStatusColor(updatedExchange.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: _buildActionButtons(updatedExchange),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 1),
            // 2. This separate StreamBuilder handles only the messages list.
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _fs.getMessages(widget.exchange.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const SizedBox(); // Removed circular loader
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No messages yet'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMyMessage = message.senderId == _currentUser?.uid;
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: _MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isMyMessage: isMyMessage,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                        Icons.send,
                        color: _isSending ?
                        Colors.grey : Theme.of(context).iconTheme.color),

                    onPressed: _isSending ? null : _sendMessage,
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMyMessage;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMyMessage
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMyMessage ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: isMyMessage
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ExchangeDetailsSheet extends StatelessWidget {
  final ExchangeRequest exchange;
  final UserModel otherUser;

  const _ExchangeDetailsSheet({
    required this.exchange,
    required this.otherUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exchange Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Status:', exchange.status.toString().split('.').last.toUpperCase()),
          _buildDetailRow('Teaching:', exchange.senderSkill),
          _buildDetailRow('Learning:', exchange.receiverSkill),
          if (exchange.location != null)
            _buildDetailRow('Location:', exchange.location!),
          if (exchange.scheduledDate != null)
            _buildDetailRow(
              'Date:',
              '${exchange.scheduledDate!.day}/${exchange.scheduledDate!.month}/${exchange.scheduledDate!.year}',
            ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}