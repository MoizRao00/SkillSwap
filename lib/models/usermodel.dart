// lib/models/usermodel.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  String? phoneNumber; // Made nullable and non-final
  String? profileImageUrl; // Made nullable and non-final
  final String bio;
  final List<String> skillsToTeach;
  final List<String> skillsToLearn;
  Map<String, dynamic>? availability; // Made nullable and non-final
  Map<String, dynamic>? ratings; // Made nullable and non-final
  final GeoPoint? location;
  String? geohash; // Made nullable and non-final
  String? locationName; // <--- NEW: Human-readable location name
  final double rating;
  final int totalExchanges;
  final List<String> reviews;
  final DateTime createdAt;
  DateTime lastActive; // Non-final as it updates
  bool isAvailable; // Non-final as it updates
  final bool isVerified;
  final List<String> portfolio;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.bio = '',
    this.skillsToTeach = const [],
    this.skillsToLearn = const [],
    this.availability,
    this.ratings,
    this.location,
    this.geohash,
    this.locationName, // <--- NEW: Add to constructor
    this.rating = 0.0,
    this.totalExchanges = 0,
    this.reviews = const [],
    required this.createdAt,
    required this.lastActive,
    this.isAvailable = true,
    this.isVerified = false,
    this.portfolio = const [],
  });

  // Factory constructor for creating a UserModel object from a Map (Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      phoneNumber: data['phoneNumber'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      bio: data['bio'] as String? ?? '',
      skillsToTeach: List<String>.from(data['skillsToTeach'] ?? []),
      skillsToLearn: List<String>.from(data['skillsToLearn'] ?? []),
      availability: data['availability'] is Map ? Map<String, dynamic>.from(data['availability']) : null,
      ratings: data['ratings'] is Map ? Map<String, dynamic>.from(data['ratings']) : null,
      location: data['location'] is GeoPoint ? data['location'] as GeoPoint : null,
      geohash: data['geohash'] as String?,
      locationName: data['locationName'] as String?, // <--- NEW: Read from map
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalExchanges: data['totalExchanges'] as int? ?? 0,
      reviews: List<String>.from(data['reviews'] ?? []),
      // Firestore Timestamps are usually converted to DateTime.
      // Your current parsing assumes String, which might be risky if Firestore sends Timestamps.
      // If Firestore sends Timestamps, change this:
      createdAt: (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : DateTime.parse(data['createdAt'] as String),
      lastActive: (data['lastActive'] is Timestamp) ? (data['lastActive'] as Timestamp).toDate() : DateTime.parse(data['lastActive'] as String),
      isAvailable: data['isAvailable'] as bool? ?? true,
      isVerified: data['isVerified'] as bool? ?? false,
      portfolio: List<String>.from(data['portfolio'] ?? []),
    );
  }

  // Method to convert a UserModel object to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'skillsToTeach': skillsToTeach,
      'skillsToLearn': skillsToLearn,
      'availability': availability,
      'ratings': ratings,
      'location': location,
      'geohash': geohash,
      'locationName': locationName, // <--- NEW: Write to map
      'rating': rating,
      'totalExchanges': totalExchanges,
      'reviews': reviews,
      // For Firestore, it's generally best to save DateTimes as Timestamps
      'createdAt': Timestamp.fromDate(createdAt), // Changed to Timestamp
      'lastActive': Timestamp.fromDate(lastActive), // Changed to Timestamp
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'portfolio': portfolio,
    };
  }

  // Optional: copyWith method for convenient updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? bio,
    List<String>? skillsToTeach,
    List<String>? skillsToLearn,
    Map<String, dynamic>? availability,
    Map<String, dynamic>? ratings,
    GeoPoint? location,
    String? geohash,
    String? locationName, // <--- NEW: Add to copyWith
    double? rating,
    int? totalExchanges,
    List<String>? reviews,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isAvailable,
    bool? isVerified,
    List<String>? portfolio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      skillsToTeach: skillsToTeach ?? this.skillsToTeach,
      skillsToLearn: skillsToLearn ?? this.skillsToLearn,
      availability: availability ?? this.availability,
      ratings: ratings ?? this.ratings,
      location: location ?? this.location,
      geohash: geohash ?? this.geohash,
      locationName: locationName ?? this.locationName, // <--- NEW: Assign in copyWith
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