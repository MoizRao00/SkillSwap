// lib/models/review_model.dart

class Review {
  final String id;
  final String exchangeId;
  final String reviewerId;
  final String reviewedUserId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.exchangeId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exchangeId': exchangeId,
      'reviewerId': reviewerId,
      'reviewedUserId': reviewedUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      exchangeId: map['exchangeId'],
      reviewerId: map['reviewerId'],
      reviewedUserId: map['reviewedUserId'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}