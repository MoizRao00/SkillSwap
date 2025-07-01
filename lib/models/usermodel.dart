import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  String? phoneNumber;
  String? profileImageUrl;
  final String bio;
  final List<String> skillsToTeach;
  final List<String> skillsToLearn;
  Map<String, dynamic>? availability;
  Map<String, dynamic>? ratings;
  final GeoPoint? location;
  String? geohash;
  String? locationName;
  final double rating;
  final int totalExchanges;
  final int totalReviews;
  final List<String> reviews;
  final DateTime createdAt;
  DateTime lastActive;
  bool isAvailable;
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
    this.locationName,
    this.rating = 0.0,
    this.totalExchanges = 0,
    this.totalReviews = 0,
    this.reviews = const [],
    required this.createdAt,
    required this.lastActive,
    this.isAvailable = true,
    this.isVerified = false,
    this.portfolio = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    // --- Start of specific field debugging ---
    final String uid =
        data['uid']
            as String; // This should generally be safe if document exists

    final String email =
        data['email'] as String; // This should generally be safe

    final String name = data['name'] as String; // This should generally be safe

    final String? phoneNumber = data['phoneNumber'] as String?;

    final String? profileImageUrl = data['profileImageUrl'] as String?;

    final String bio = data['bio'] as String? ?? '';

    final List<String> skillsToTeach =
        (data['skillsToTeach'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    final List<String> skillsToLearn =
        (data['skillsToLearn'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    final Map<String, dynamic>? availability = data['availability'] is Map
        ? Map<String, dynamic>.from(data['availability'])
        : null;

    final Map<String, dynamic>? ratings = data['ratings'] is Map
        ? Map<String, dynamic>.from(data['ratings'])
        : null;

    final GeoPoint? location = data['location'] is GeoPoint
        ? data['location'] as GeoPoint
        : null;

    final String? geohash = data['geohash'] as String?;

    final String? locationName = data['locationName'] as String?;

    final double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;

    final int totalExchanges = data['totalExchanges'] as int? ?? 0;

    final int totalReviews =
        data['totalReviews'] as int? ?? 0; // This was the one we discussed

    final List<String> reviews =
        (data['reviews'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final DateTime createdAt = (data['createdAt'] is Timestamp)
        ? (data['createdAt'] as Timestamp).toDate()
        : (data['createdAt'] != null
              ? DateTime.parse(data['createdAt'].toString())
              : DateTime.now());

    final DateTime lastActive = (data['lastActive'] is Timestamp)
        ? (data['lastActive'] as Timestamp).toDate()
        : (data['lastActive'] != null
              ? DateTime.parse(data['lastActive'].toString())
              : DateTime.now());

    final bool isAvailable = data['isAvailable'] as bool? ?? true;

    final bool isVerified = data['isVerified'] as bool? ?? false;

    final List<String> portfolio =
        (data['portfolio'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    // --- End of specific field debugging ---

    return UserModel(
      uid: uid,
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
      bio: bio,
      skillsToTeach: skillsToTeach,
      skillsToLearn: skillsToLearn,
      availability: availability,
      ratings: ratings,
      location: location,
      geohash: geohash,
      locationName: locationName,
      rating: rating,
      totalExchanges: totalExchanges,
      totalReviews: totalReviews,
      reviews: reviews,
      createdAt: createdAt,
      lastActive: lastActive,
      isAvailable: isAvailable,
      isVerified: isVerified,
      portfolio: portfolio,
    );
  }

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
      'locationName': locationName,
      'rating': rating,
      'totalExchanges': totalExchanges,
      'totalReviews': totalReviews,
      'reviews': reviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'portfolio': portfolio,
    };
  }

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
    String? locationName,
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
      locationName: locationName ?? this.locationName,
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
