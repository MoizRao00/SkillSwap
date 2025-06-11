// lib/models/portfolio_item.dart
class PortfolioItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime date;
  final List<String> tags;

  PortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.date,
    required this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'tags': tags,
    };
  }

  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      date: DateTime.parse(map['date']),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

// lib/models/achievement.dart
class Achievement {
  final String id;
  final String title;
  final String description;
  final String? badgeUrl;
  final DateTime date;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.badgeUrl,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'badgeUrl': badgeUrl,
      'date': date.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      badgeUrl: map['badgeUrl'],
      date: DateTime.parse(map['date']),
    );
  }
}
