import 'package:cloud_firestore/cloud_firestore.dart';

enum ExchangeStatus {
  pending,
  accepted,
  declined,
  confirmedBySender,
  confirmedByReceiver,
  completed,
  cancelled,
}

class ExchangeRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderSkill;
  final String receiverSkill;
  final ExchangeStatus status;
  final DateTime createdAt;
  final String? location;
  final DateTime? scheduledDate;

  ExchangeRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderSkill,
    required this.receiverSkill,
    required this.status,
    required this.createdAt,
    this.location,
    this.scheduledDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderSkill': senderSkill,
      'receiverSkill': receiverSkill,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt), // Convert DateTime to Timestamp
      'location': location,
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null, // Convert DateTime to Timestamp
    };
  }

  factory ExchangeRequest.fromMap(Map<String, dynamic> map, String docId) {
    ExchangeStatus parseStatus(String statusString) {
      return ExchangeStatus.values.firstWhere(
            (e) => e.name == statusString,
        orElse: () => ExchangeStatus.pending,
      );
    }

    // Handle different timestamp formats
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      }
      return DateTime.now(); // fallback
    }

    return ExchangeRequest(
      id: docId,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      senderSkill: map['senderSkill'] as String,
      receiverSkill: map['receiverSkill'] as String,
      status: parseStatus(map['status'] as String),
      createdAt: parseTimestamp(map['createdAt']),
      location: map['location'] as String?,
      scheduledDate: map['scheduledDate'] != null ? parseTimestamp(map['scheduledDate']) : null,
    );
  }
}