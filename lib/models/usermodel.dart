class UserModel {
  // Basic user identification
  final String uid;              // Firebase Auth UID - unique identifier
  final String email;            // User's email address
  final String name;             // User's display name

  // Profile information
  final String? profilePicUrl;   // URL to profile picture in Firebase Storage
  final String? bio;             // Short description about the user
  final String? phone;           // Contact number (optional)
  final String? location;        // User's city/area for local exchanges

  // Skills-related data
  final List<String> skillsToTeach;  // Skills user can offer to others
  final List<String> skillsToLearn;  // Skills user wants to learn

  // Reputation system
  final double rating;           // Average rating (0.0 to 5.0)
  final int totalExchanges;      // Total completed skill exchanges
  final List<String> reviews;    // List of review IDs (references to review collection)

  // User activity
  final DateTime createdAt;      // When account was created
  final DateTime lastActive;     // Last time user was online
  final bool isAvailable;        // Is user currently available for exchanges
  final bool isVerified;         // Is user verified (email/phone verification)

  // Constructor - creates new UserModel instance
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
  });

  // Convert UserModel to Map for storing in Firestore
  // Firestore stores data as Map<String, dynamic>
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
      'createdAt': createdAt.toIso8601String(), // Convert DateTime to String
      'lastActive': lastActive.toIso8601String(),
      'isAvailable': isAvailable,
      'isVerified': isVerified,
    };
  }

  // Create UserModel from Firestore document data
  // This converts Map back to UserModel object
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
      createdAt: DateTime.parse(map['createdAt']), // Convert String back to DateTime
      lastActive: DateTime.parse(map['lastActive']),
      isAvailable: map['isAvailable'] ?? true,
      isVerified: map['isVerified'] ?? false,
    );
  }

  // Create a copy of UserModel with some fields updated
  // This is useful for updating user data without creating completely new object
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
    );
  }

  // Convert UserModel to String (useful for debugging)
  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, skillsToTeach: $skillsToTeach, skillsToLearn: $skillsToLearn, rating: $rating)';
  }

  // Compare two UserModel objects
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  // Generate hash code (required when overriding ==)
  @override
  int get hashCode => uid.hashCode;
}