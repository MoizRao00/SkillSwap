import 'package:flutter/material.dart';
import '../../models/exchange_request.dart';
import '../../screens/chat/chat_screen.dart';
import '../../services/firestore_service.dart';

class ExchangeActionButtons extends StatelessWidget {
  final ExchangeRequest request;
  final String currentUserId;
  final FirestoreService fs;

  const ExchangeActionButtons({
    required this.request,
    required this.currentUserId,
    required this.fs,
    super.key,
  });

  String _getStatusText(ExchangeStatus status, bool isSender) {
    switch (status) {
      case ExchangeStatus.confirmedBySender:
        return isSender ? 'Waiting for Receiver' : 'Confirm Completion';
      case ExchangeStatus.confirmedByReceiver:
        return isSender ? 'Confirm Completion' : 'Waiting for Sender';
      case ExchangeStatus.completed:
        return 'Completed';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request.status;
    final isSender = currentUserId == request.senderId;

    Widget _buildCompletionButton() {
      switch (status) {
        case ExchangeStatus.accepted:
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Mark as Completed'),
              onPressed: () => fs.updateExchangeStatus(request.id, ExchangeStatus.completed),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          );

        case ExchangeStatus.confirmedBySender:
        case ExchangeStatus.confirmedByReceiver:
          final isWaiting = (status == ExchangeStatus.confirmedBySender && isSender) ||
              (status == ExchangeStatus.confirmedByReceiver && !isSender);

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: Icon(isWaiting ? Icons.hourglass_empty : Icons.check_circle),
              label: Text(_getStatusText(status, isSender)),
              onPressed: isWaiting ? null : () =>
                  fs.updateExchangeStatus(request.id, ExchangeStatus.completed),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: isWaiting ? Colors.grey.shade200 : null,
              ),
            ),
          );

        case ExchangeStatus.completed:
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Completed'),
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          );

        default:
          return const SizedBox.shrink();
      }
    }

    if (status == ExchangeStatus.pending) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSender)
              TextButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text("Cancel Request"),
                onPressed: () => fs.updateExchangeStatus(
                    request.id,
                    ExchangeStatus.cancelled
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              )
            else
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Accept"),
                    onPressed: () => fs.updateExchangeStatus(
                        request.id,
                        ExchangeStatus.accepted
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Decline"),
                    onPressed: () => fs.updateExchangeStatus(
                        request.id,
                        ExchangeStatus.declined
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    } else if (status == ExchangeStatus.accepted ||
        status == ExchangeStatus.confirmedBySender ||
        status == ExchangeStatus.confirmedByReceiver ||
        status == ExchangeStatus.completed) {
      return Column(
        children: [
          _buildCompletionButton(),
          if (status != ExchangeStatus.completed)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text("Chat"),
                onPressed: () async {
                  final otherUser = await fs.getUser(
                    currentUserId == request.senderId
                        ? request.receiverId
                        : request.senderId,
                  );
                  if (otherUser != null && context.mounted) {
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
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}