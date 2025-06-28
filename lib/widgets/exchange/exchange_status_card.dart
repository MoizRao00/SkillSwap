import 'package:flutter/material.dart';
import 'package:skillswap/widgets/exchange/string_extension.dart';
import '../../models/exchange_request.dart';
import '../../services/firestore_service.dart';

class ExchangeStatusCard extends StatelessWidget {
  final ExchangeStatus status;

  const ExchangeStatusCard({required this.status, super.key});

  String _getLabel() {
    switch (status) {
      case ExchangeStatus.pending:
        return 'Pending';
      case ExchangeStatus.accepted:
        return 'Accepted';
      case ExchangeStatus.confirmedBySender:
        return 'Confirmed by Sender';
      case ExchangeStatus.confirmedByReceiver:
        return 'Confirmed by Receiver';
      case ExchangeStatus.completed:
        return 'Completed';
      case ExchangeStatus.declined:
        return 'Declined';
      case ExchangeStatus.cancelled:
        return 'Cancelled';
      default:
        return '';
    }
  }

  Color _getColor() {
    switch (status) {
      case ExchangeStatus.pending:
        return Colors.orange;
      case ExchangeStatus.accepted:
        return Colors.blue;
      case ExchangeStatus.confirmedBySender:
      case ExchangeStatus.confirmedByReceiver:
        return Colors.purple;
      case ExchangeStatus.completed:
        return Colors.green;
      case ExchangeStatus.cancelled:
      case ExchangeStatus.declined:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_getLabel()),
      backgroundColor: _getColor().withOpacity(0.2),
      labelStyle: TextStyle(color: _getColor()),
    );
  }
}