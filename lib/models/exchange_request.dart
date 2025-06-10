// lib/models/exchange_request.dart

enum ExchangeStatus {
  pending,
  accepted,
  declined,
  completed,
  cancelled
}

class ExchangeRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderSkill;    // Skill sender will teach
  final String receiverSkill;  // Skill receiver will teach
  final String message;
  final DateTime createdAt;
  final ExchangeStatus status;
  final DateTime? scheduledDate;
  final String? location;

  ExchangeRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderSkill,
    required this.receiverSkill,
    required this.message,
    required this.createdAt,
    this.status = ExchangeStatus.pending,
    this.scheduledDate,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderSkill': senderSkill,
      'receiverSkill': receiverSkill,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'location': location,
    };
  }

  factory ExchangeRequest.fromMap(Map<String, dynamic> map) {
    return ExchangeRequest(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      senderSkill: map['senderSkill'],
      receiverSkill: map['receiverSkill'],
      message: map['message'],
      createdAt: DateTime.parse(map['createdAt']),
      status: ExchangeStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => ExchangeStatus.pending,
      ),
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.parse(map['scheduledDate'])
          : null,
      location: map['location'],
    );
  }
}