// lib/models/activity_model.dart

enum ActivityType {
  exchangeRequest,
  exchangeAccepted,
  exchangeCompleted,
  newReview,
  skillAdded,
  profileUpdate
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
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isRead': isRead,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      userId: map['userId'],
      type: ActivityType.values.firstWhere(
            (e) => e.toString() == map['type'],
        orElse: () => ActivityType.profileUpdate,
      ),
      title: map['title'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
      data: map['data'] ?? {},
      isRead: map['isRead'] ?? false,
    );
  }
}