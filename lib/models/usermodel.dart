// lib/models/usermodel.dart

import 'package:skillswap/models/potfolio_item.dart'; // Make sure this path is correct

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profilePicUrl;
  final String? bio;
  final String? phone;
  final String? location;
  final List<String> skillsToTeach;
  final List<String>  skillsToLearn;
  final double rating;
  final int totalExchanges;
  final List<String> reviews;
  final DateTime createdAt; // This is now non-nullable, so it needs a default or safe parsing
  final DateTime lastActive; // This is now non-nullable, so it needs a default or safe parsing
  final bool isAvailable;
  final bool isVerified;
  final List<PortfolioItem> portfolio;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profilePicUrl,
    this.bio,
    this.phone,
    this.location,
    required this.skillsToTeach,
    required this.skillsToLearn,
    this.rating = 0.0,
    this.totalExchanges = 0,
    this.reviews = const [],
    required this.createdAt, // Still required in constructor, but fromMap handles defaults
    required this.lastActive, // Still required in constructor, but fromMap handles defaults
    this.isAvailable = true,
    this.isVerified = false,
    this.portfolio = const [],
  });

  // Update toMap method (no change here, but included for context)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'profilePicUrl': profilePicUrl,
      'bio': bio,
      'phone': phone,
      'location': location,
      'skillsToTeach': skillsToTeach,
      'skillsToLearn': skillsToLearn,
      'rating': rating,
      'totalExchanges': totalExchanges,
      'reviews': reviews,
      'createdAt': createdAt.toIso8601String(), // Saving as string
      'lastActive': lastActive.toIso8601String(), // Saving as string
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'portfolio': portfolio.map((item) => item.toMap()).toList(),
    };
  }

  // Update fromMap factory
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // --- NEW HELPER FUNCTION FOR SAFE DATE/TIME PARSING ---
    DateTime _parseDateTime(dynamic value) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // You can add more robust logging here if needed
          print('Error parsing DateTime from Firestore: "$value" - $e');
          // Fallback to current time if parsing fails
          return DateTime.now();
        }
      }
      // If value is not a string or is null, default to current time
      return DateTime.now();
    }
    // --- END NEW HELPER FUNCTION ---

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      profilePicUrl: map['profilePicUrl'],
      bio: map['bio'],
      phone: map['phone'],
      location: map['location'],
      skillsToTeach: List<String>.from(map['skillsToTeach'] ?? []),
      skillsToLearn: List<String>.from(map['skillsToLearn'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalExchanges: map['totalExchanges'] ?? 0,
      reviews: List<String>.from(map['reviews'] ?? []),
      createdAt: _parseDateTime(map['createdAt']), // <--- Use the helper here
      lastActive: _parseDateTime(map['lastActive']), // <--- Use the helper here
      isAvailable: map['isAvailable'] ?? true,
      isVerified: map['isVerified'] ?? false,
      portfolio: (map['portfolio'] as List<dynamic>?)
          ?.map((item) => PortfolioItem.fromMap(item as Map<String, dynamic>)) // Ensure cast to Map<String, dynamic>
          .toList() ?? [],
    );
  }

  // Update copyWith method (no change here, but included for context)
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? profilePicUrl,
    String? bio,
    String? phone,
    String? location,
    List<String>? skillsToTeach,
    List<String>? skillsToLearn,
    double? rating,
    int? totalExchanges,
    List<String>? reviews,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isAvailable,
    bool? isVerified,
    List<PortfolioItem>? portfolio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      skillsToTeach: skillsToTeach ?? this.skillsToTeach,
      skillsToLearn: skillsToLearn ?? this.skillsToLearn,
      rating: rating ?? this.rating,
      totalExchanges: totalExchanges ?? this.totalExchanges,
      reviews: reviews ?? this.reviews,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      portfolio: portfolio ?? this.portfolio,
    );
  }
}