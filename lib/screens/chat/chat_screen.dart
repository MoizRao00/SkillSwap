
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/exchange_request.dart';
import '../../models/chat_message.dart';
import '../../models/usermodel.dart';
import '../../services/firestore_service.dart';
import '../../widgets/animation/fade_animation.dart';
import '../../widgets/animation/slide_animation.dart';


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(
        titleSpacing: 0,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: widget.otherUser.profilePicUrl != null
                ? NetworkImage(widget.otherUser.profilePicUrl!)
                : null,
            child: widget.otherUser.profilePicUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
            widget.otherUser.name,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            '${widget.exchange.senderSkill} ↔ ${widget.exchange.receiverSkill}',
            style: Theme
                .of(context)
                .textTheme
                .bodySmall,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showExchangeDetails(context),
          ),
        ],
      ),
      body:
      SafeArea(
        child: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: _getStatusColor().withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 16,
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(),
                    style: TextStyle(color: _getStatusColor()),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _fs.getMessages(widget.exchange.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64,
                              color: Colors.grey),
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
                      return _MessageBubble(
                        message: message,
                        isMyMessage: isMyMessage,
                      );
                    },
                  );
                },
              ),
            ),

            // Message Input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme
                    .of(context)
                    .cardColor,
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
                    icon: _isSending
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send),
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

  Color _getStatusColor() {
    switch (widget.exchange.status) {
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
    switch (widget.exchange.status) {
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

  String _getStatusText() {
    switch (widget.exchange.status) {
      case ExchangeStatus.pending:
        return 'Exchange request is pending';
      case ExchangeStatus.accepted:
        return 'Exchange is active';
      case ExchangeStatus.completed:
        return 'Exchange completed';
      case ExchangeStatus.declined:
        return 'Exchange declined';
      case ExchangeStatus.cancelled:
        return 'Exchange cancelled';
    }
  }
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _fs.sendMessage(
        widget.exchange.id,
        message,
      );
      _messageController.clear();

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showExchangeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
            _buildDetailRow('Status:', widget.exchange.status.toString().split('.').last.toUpperCase()),
            _buildDetailRow('Teaching:', widget.exchange.senderSkill),
            _buildDetailRow('Learning:', widget.exchange.receiverSkill),
            if (widget.exchange.location != null)
              _buildDetailRow('Location:', widget.exchange.location!),
            if (widget.exchange.scheduledDate != null)
              _buildDetailRow(
                'Date:',
                '${widget.exchange.scheduledDate!.day}/${widget.exchange.scheduledDate!.month}/${widget.exchange.scheduledDate!.year}',
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
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMyMessage;

  const _MessageBubble({
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
              message.message,
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
          Text(value),
        ],
      ),
    );
  }
}
