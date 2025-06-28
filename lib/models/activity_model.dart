import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  exchangeRequest,
  exchangeAccepted,
  exchangeCompleted,
  newReview,
  skillAdded,
  profileUpdate,
  exchangeDeclined,
}

class Activity {
  final String id;
  final String userId;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isRead;

  Activity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.data,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name, // Use enum name
      'title': title,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'data': data,
      'isRead': isRead,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return DateTime.now(); // fallback
    }

    return Activity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: ActivityType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ActivityType.profileUpdate,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: parseTimestamp(map['timestamp']),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
    );
  }
}