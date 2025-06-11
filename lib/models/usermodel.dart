// In lib/models/usermodel.dart

import 'package:skillswap/models/potfolio_item.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profilePicUrl;
  final String? bio;
  final String? phone;
  final String? location;
  final List<String> skillsToTeach;
  final List<String> skillsToLearn;
  final double rating;
  final int totalExchanges;
  final List<String> reviews;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isAvailable;
  final bool isVerified;
  // Add this new field
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
    required this.createdAt,
    required this.lastActive,
    this.isAvailable = true,
    this.isVerified = false,
    this.portfolio = const [], // Add this
  });

  // Update toMap method
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
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'portfolio': portfolio.map((item) => item.toMap()).toList(), // Add this
    };
  }

  // Update fromMap factory
  factory UserModel.fromMap(Map<String, dynamic> map) {
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
      createdAt: DateTime.parse(map['createdAt']),
      lastActive: DateTime.parse(map['lastActive']),
      isAvailable: map['isAvailable'] ?? true,
      isVerified: map['isVerified'] ?? false,
      portfolio: (map['portfolio'] as List<dynamic>?)
          ?.map((item) => PortfolioItem.fromMap(item))
          .toList() ?? [], // Add this
    );
  }

  // Update copyWith method
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
    List<PortfolioItem>? portfolio, // Add this
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
      portfolio: portfolio ?? this.portfolio, // Add this
    );
  }
}