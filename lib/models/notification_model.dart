import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  exchangeRequest,
  exchangeAccepted,
  exchangeCompleted,
  newMessage,
  newReview
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name, // Use enum name instead of toString()
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'data': data,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return DateTime.now(); // fallback
    }

    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => NotificationType.exchangeRequest,
      ),
      timestamp: parseTimestamp(map['timestamp']),
      isRead: map['isRead'] ?? false,
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
}