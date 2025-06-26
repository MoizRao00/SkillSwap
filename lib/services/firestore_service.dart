// lib/services/firestore_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:dart_geohash/dart_geohash.dart';

import '../models/activity_model.dart';
import '../models/chat_message.dart';
import '../models/exchange_request.dart';
import '../models/notification_model.dart';
import '../models/potfolio_item.dart';
import '../models/review_model.dart';
import '../models/skill_model.dart';
import '../models/usermodel.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeoHasher _geoHasher = GeoHasher();

  FirestoreService._privateConstructor();
  static final FirestoreService _instance = FirestoreService._privateConstructor();
  factory FirestoreService() {
    return _instance;
  }

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // --- Exchange Request Methods ---
  Stream<List<ExchangeRequest>> getExchangeRequests({
    required String userId,
    required bool isReceived,
  }) {
    return _firestore
        .collection('exchanges')
        .where(isReceived ? 'receiverId' : 'senderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            ExchangeRequest.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<bool> createExchangeRequest({
    required String receiverId,
    required String senderSkill,
    required String receiverSkill,
    required String message,
    String? location, // This `location` is a String, not GeoPoint. Renamed to `locationText` for clarity
    DateTime? scheduledDate,
  }) async {
    try {
      final sender = FirebaseAuth.instance.currentUser;
      if (sender == null) return false;

      final docRef = _firestore.collection('exchanges').doc();
      final request = ExchangeRequest(
        id: docRef.id,
        senderId: sender.uid,
        receiverId: receiverId,
        senderSkill: senderSkill,
        receiverSkill: receiverSkill,
        message: message,
        createdAt: DateTime.now(),
        // This `location` in ExchangeRequest refers to the text input field from the UI
        location: location, // Still using this for the message/request's preferred location
        scheduledDate: scheduledDate,
        status: ExchangeStatus.pending,
      );

      await docRef.set(request.toMap());

      await createActivity(
        userId: receiverId,
        type: ActivityType.exchangeRequest,
        title: 'New Exchange Request',
        description: 'Someone wants to exchange $senderSkill for $receiverSkill',
        data: {
          'exchangeId': docRef.id,
          'senderId': sender.uid,
          'senderSkill': senderSkill,
          'receiverSkill': receiverSkill,
        },
      );

      return true;
    } catch (e) {
      print('❌ Error creating exchange request: $e');
      return false;
    }
  }

  Stream<List<ExchangeRequest>> getUserExchangeRequests() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('exchanges')
        .where('senderId', isEqualTo: userId)
        .snapshots()
        .asyncMap((sent) async {
      final received = await _firestore
          .collection('exchanges')
          .where('receiverId', isEqualTo: userId)
          .get();

      final requests = [
        ...sent.docs.map((doc) => ExchangeRequest.fromMap(doc.data())),
        ...received.docs.map((doc) => ExchangeRequest.fromMap(doc.data())),
      ];

      return requests..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<bool> updateExchangeStatus(
      String exchangeId,
      ExchangeStatus status,
      ) async {
    try {
      await _firestore.collection('exchanges').doc(exchangeId).update({
        'status': status.toString(),
      });

      final exchange = await _firestore.collection('exchanges').doc(exchangeId).get();
      final exchangeData = exchange.data();
      if (exchangeData == null) return true;

      switch (status) {
        case ExchangeStatus.accepted:
          await createActivity(
            userId: exchangeData['senderId'],
            type: ActivityType.exchangeAccepted,
            title: 'Exchange Request Accepted',
            description: 'Your exchange request has been accepted',
            data: {
              'exchangeId': exchangeId,
              'receiverId': exchangeData['receiverId'],
            },
          );
          break;

        case ExchangeStatus.completed:
          await createActivity(
            userId: exchangeData['senderId'],
            type: ActivityType.exchangeCompleted,
            title: 'Exchange Completed',
            description: 'Skill exchange completed successfully',
            data: {
              'exchangeId': exchangeId,
              'receiverId': exchangeData['receiverId'],
            },
          );
          await createActivity(
            userId: exchangeData['receiverId'],
            type: ActivityType.exchangeCompleted,
            title: 'Exchange Completed',
            description: 'Skill exchange completed successfully',
            data: {
              'exchangeId': exchangeId,
              'senderId': exchangeData['senderId'],
            },
          );
          break;

        case ExchangeStatus.declined:
          await createActivity(
            userId: exchangeData['senderId'],
            type: ActivityType.exchangeDeclined,
            title: 'Exchange Request Declined',
            description: 'Your exchange request was declined',
            data: {
              'exchangeId': exchangeId,
              'receiverId': exchangeData['receiverId'],
            },
          );
          break;

        case ExchangeStatus.pending:
        case ExchangeStatus.cancelled:
          break;
      }

      return true;
    } catch (e) {
      print('❌ Error updating exchange status: $e');
      return false;
    }
  }

  // --- User Management Methods ---

  Future<bool> createInitialUserProfile(User firebaseUser) async {
    try {
      final exists = await userExists(firebaseUser.uid);
      if (exists) {
        print('✅ User profile already exists');
        return true;
      }

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'New User',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        phoneNumber: firebaseUser.phoneNumber,
        profileImageUrl: firebaseUser.photoURL,
        isVerified: firebaseUser.emailVerified,
        bio: '',
        skillsToTeach: [],
        skillsToLearn: [],
        availability: {},
        ratings: {},
        location: null,
        geohash: null,
        locationName: null, // <--- NEW: Initialize locationName
      );

      return await saveUser(newUser);
    } catch (e) {
      print('❌ Error creating initial profile: $e');
      return false;
    }
  }

  Future<bool> saveUser(UserModel user) async {
    try {
      Map<String, dynamic> userData = user.toMap();

      // Automatically generate geohash if location is present
      if (user.location != null) {
        userData['geohash'] = _geoHasher.encode(
          user.location!.longitude,
          user.location!.latitude,
          precision: 9,
        );
      } else {
        userData['geohash'] = null;
      }
      // No change needed for locationName here, as it's part of user.toMap() now.

      await _firestore.collection('users').doc(user.uid).set(userData);
      print('✅ User saved successfully: ${user.name}');
      return true;
    } catch (e) {
      print('❌ Error saving user: $e');
      return false;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        // UserModel.fromMap now handles the 'uid' from the map, not as a separate argument
        return UserModel.fromMap(doc.data()!);
      } else {
        print('❌ User not found: $uid');
        return null;
      }
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        // UserModel.fromMap now handles the 'uid' from the map, not as a separate argument
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<UserModel?> getCurrentUser() async {
    if (currentUserId != null) {
      return await getUser(currentUserId!);
    }
    return null;
  }

  // UPDATED: updateUser method to properly handle locationName and geohash
  Future<bool> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      // Always update lastActive
      updates['lastActive'] = Timestamp.fromDate(DateTime.now()); // Changed to Timestamp

      // If location (GeoPoint) is being updated, recalculate geohash
      if (updates.containsKey('location') && updates['location'] is GeoPoint) {
        final GeoPoint loc = updates['location'];
        updates['geohash'] = _geoHasher.encode(
          loc.longitude,
          loc.latitude,
          precision: 9,
        );
      } else if (updates.containsKey('location') && updates['location'] == null) {
        // If location is being set to null, also nullify geohash
        updates['geohash'] = null;
      }
      // No specific handling for 'locationName' here, as it will just be updated if present in the 'updates' map.

      await _firestore.collection('users').doc(uid).update(updates);
      print('✅ User updated successfully: $uid');
      return true;
    } catch (e) {
      print('❌ Error updating user: $e');
      return false;
    }
  }

  // You have createUserDocument. Ensure it also initializes locationName to null.
  Future<void> createUserDocument(String uid, String name, String email) async {
    final now = DateTime.now();
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'profileImageUrl': null,
      'bio': '',
      'phoneNumber': null,
      'location': null,
      'geohash': null,
      'locationName': null, // <--- NEW: Initialize locationName here too
      'skillsToTeach': [],
      'skillsToLearn': [],
      'rating': 0.0,
      'totalExchanges': 0,
      'reviews': [],
      'createdAt': Timestamp.fromDate(now), // Changed to Timestamp
      'lastActive': Timestamp.fromDate(now), // Changed to Timestamp
      'isAvailable': true,
      'isVerified': false,
      'portfolio': [],
    });
  }

  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  Future<void> updateAvailability(String uid, bool isAvailable) async {
    await _firestore.collection('users').doc(uid).update({
      'isAvailable': isAvailable,
      'lastActive': Timestamp.fromDate(DateTime.now()), // Changed to Timestamp
    });
  }

  Future<bool> updateUserRating(String uid, double newRating, int totalExchanges) async {
    return await updateUser(uid, {
      'rating': newRating,
      'totalExchanges': totalExchanges,
    });
  }

  // --- Skill Management Methods ---

  Future<List<Skill>> getUserSkills(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).collection('skills').get();
      return snap.docs.map((doc) => Skill.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting user skills: $e');
      return [];
    }
  }

  Stream<List<Skill>> getUserSkillsStream(String uid) {
    return _firestore.collection('users').doc(uid).collection('skills').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Skill.fromMap(doc.id, doc.data())).toList());
  }

  Future<bool> addUserSkill(String uid, String skillName) async {
    print('🔍 addUserSkill called for uid=$uid, skill="$skillName"');
    try {
      final col = _firestore.collection('users').doc(uid).collection('skills');
      final docRef = await col.add({'name': skillName});
      print('✅ Skill doc created with ID=${docRef.id}');

      await updateUser(uid, {
        'skillsToTeach': FieldValue.arrayUnion([skillName])
      });

      await createActivity(
        userId: uid,
        type: ActivityType.skillAdded,
        title: 'New Skill Added',
        description: 'You added $skillName to your teaching skills',
        data: {
          'skillName': skillName,
          'skillId': docRef.id,
        },
      );
      return true;
    } catch (e) {
      print('❌ addUserSkill error: $e');
      return false;
    }
  }

  Future<bool> removeUserSkill(String uid, String skillId, String skillName) async {
    try {
      await _firestore.collection('users').doc(uid).collection('skills').doc(skillId).delete();
      await updateUser(uid, {
        'skillsToTeach': FieldValue.arrayRemove([skillName])
      });
      print('✅ Skill removed successfully: $skillName');
      return true;
    } catch (e) {
      print('❌ Error removing skill: $e');
      return false;
    }
  }

  Future<bool> addLearningSkill(String uid, String skillName) async {
    try {
      await updateUser(uid, {
        'skillsToLearn': FieldValue.arrayUnion([skillName])
      });
      return true;
    } catch (e) {
      print('❌ Error adding learning skill: $e');
      return false;
    }
  }

  Future<bool> removeLearningSkill(String uid, String skillId, String skillName) async {
    try {
      await updateUser(uid, {
        'skillsToLearn': FieldValue.arrayRemove([skillName])
      });
      return true;
    } catch (e) {
      print('❌ Error removing learning skill: $e');
      return false;
    }
  }

  Stream<List<Skill>> getUserLearningSkillsStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data != null && data['skillsToLearn'] != null) {
        return (data['skillsToLearn'] as List)
            .map((skill) => Skill(id: skill, name: skill))
            .toList();
      }
      return <Skill>[];
    });
  }

  Future<void> syncUserSkills(String uid) async {
    try {
      List<Skill> skills = await getUserSkills(uid);
      List<String> skillNames = skills.map((skill) => skill.name).toList();

      await updateUser(uid, {
        'skillsToTeach': skillNames,
      });

      print('✅ Skills synced for user: $uid');
    } catch (e) {
      print('❌ Error syncing skills: $e');
    }
  }

  // --- Chat Message Methods ---

  Future<bool> sendMessage(String exchangeId, String message) async {
    try {
      final sender = FirebaseAuth.instance.currentUser;
      if (sender == null) return false;

      final docRef = _firestore.collection('exchanges').doc(exchangeId).collection('messages').doc();

      final chatMessage = ChatMessage(
        id: docRef.id,
        senderId: sender.uid,
        message: message,
        timestamp: DateTime.now(),
      );

      await docRef.set(chatMessage.toMap());
      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  Stream<List<ChatMessage>> getMessages(String exchangeId) {
    return _firestore
        .collection('exchanges')
        .doc(exchangeId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  Future<void> markMessagesAsRead(String exchangeId, String currentUserId) async {
    try {
      final messagesQuery = await _firestore
          .collection('exchanges')
          .doc(exchangeId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  // --- Review Methods ---

  Future<bool> submitReview({
    required String exchangeId,
    required String reviewedUserId,
    required double rating,
    required String comment,
  }) async
  {
    try {
      final reviewer = FirebaseAuth.instance.currentUser;
      if (reviewer == null) return false;

      final docRef = _firestore.collection('reviews').doc();
      final review = Review(
        id: docRef.id,
        exchangeId: exchangeId,
        reviewerId: reviewer.uid,
        reviewedUserId: reviewedUserId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await docRef.set(review.toMap());

      await createActivity(
        userId: reviewedUserId,
        type: ActivityType.newReview,
        title: 'New Review Received',
        description: 'Someone left you a review',
        data: {
          'reviewId': docRef.id,
          'exchangeId': exchangeId,
          'rating': rating,
        },
      );

      return true;
    } catch (e) {
      print('❌ Error submitting review: $e');
      return false;
    }
  }

  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Review.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  Future<List<Review>> getExchangeReviews(String exchangeId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('exchangeId', isEqualTo: exchangeId)
          .get();

      return snapshot.docs
          .map((doc) => Review.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ Error getting exchange reviews: $e');
      return [];
    }
  }

  // --- Notification Methods ---

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic> data = const {},
  })
  async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      final notification = NotificationModel(
        id: docRef.id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        data: data,
      );

      await docRef.set(notification.toMap());
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // NEWLY ADDED METHOD
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false) // Only unread ones
          .get();

      final batch = _firestore.batch();
      for (var doc in notificationsQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      print('✅ All notifications marked as read for user: $userId');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  // --- Activity Methods ---

  Future<void> createActivity({
    required String userId,
    required ActivityType type,
    required String title,
    required String description,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = _firestore.collection('activities').doc();
      final activity = Activity(
        id: docRef.id,
        userId: userId,
        type: type,
        title: title,
        description: description,
        timestamp: DateTime.now(),
        data: data,
      );

      await docRef.set(activity.toMap());
    } catch (e) {
      print('❌ Error creating activity: $e');
    }
  }

  Stream<List<Activity>> getUserActivities(String userId) {
    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Activity.fromMap(doc.data())).toList());
  }

  Future<void> markActivityAsRead(String activityId) async {
    try {
      await _firestore.collection('activities').doc(activityId).update({'isRead': true});
    } catch (e) {
      print('❌ Error marking activity as read: $e');
    }
  }

  Stream<List<dynamic>> getRecentActivities() {
    return Stream.value([]); // Placeholder: Implement based on your activity tracking
  }

  // --- Portfolio Methods ---

  Stream<List<PortfolioItem>> getUserPortfolio(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('portfolio')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PortfolioItem.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  Future<void> addPortfolioItem(
      String userId, {
        required String title,
        required String description,
        required List<String> tags,
        String? imageUrl,
      }) async {
    try {
      final docRef = _firestore.collection('users').doc(userId).collection('portfolio').doc();

      final item = PortfolioItem(
        id: docRef.id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        date: DateTime.now(),
        tags: tags,
      );

      await docRef.set(item.toMap());

      await createActivity(
        userId: userId,
        type: ActivityType.profileUpdate,
        title: 'Portfolio Updated',
        description: 'Added new portfolio item: $title',
        data: {
          'portfolioItemId': docRef.id,
        },
      );
    } catch (e) {
      print('❌ Error adding portfolio item: $e');
    }
  }

  Future<void> deletePortfolioItem(String userId, String itemId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('portfolio').doc(itemId).delete();
    } catch (e) {
      print('❌ Error deleting portfolio item: $e');
    }
  }

  // --- Search & Query Operations ---

  Stream<List<UserModel>> getNearbyUsers(GeoPoint? currentUserLocation, String currentUserId) {
    if (currentUserLocation == null || currentUserId.isEmpty) {
      print("Warning: getNearbyUsers called with null location or empty userId.");
      return Stream.value([]);
    }

    final double radiusInKm = 50.0;
    final int geohashPrecision = 7;

    final String centralGeohash = _geoHasher.encode(
      currentUserLocation.longitude,
      currentUserLocation.latitude,
      precision: geohashPrecision,
    );

    return _firestore
        .collection('users')
        .where('geohash', isGreaterThanOrEqualTo: centralGeohash)
        .where('geohash', isLessThan: '${centralGeohash}z')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((user) {
      if (user.uid == currentUserId || user.location == null) {
        return false;
      }
      final distance = _calculateDistance(currentUserLocation!, user.location!);
      return distance <= radiusInKm;
    })
        .toList());
  }

  Future<List<UserModel>> searchUsers({
    required String query,
    required bool searchSkills,
    String skillType = 'teaching',
    double minRating = 0.0,
    bool onlyAvailable = false,
  }) async {
    try {
      Query usersQuery = _firestore.collection('users');

      if (onlyAvailable) {
        usersQuery = usersQuery.where('isAvailable', isEqualTo: true);
      }

      if (minRating > 0) {
        usersQuery = usersQuery.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      if (searchSkills) {
        final field = skillType == 'teaching' ? 'skillsToTeach' : 'skillsToLearn';

        usersQuery = usersQuery.where(field, arrayContains: query);
      } else {
        final lowercaseQuery = query.toLowerCase();
        usersQuery = usersQuery
            .where('name', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('name', isLessThan: '${lowercaseQuery}z');
      }

      final snapshot = await usersQuery.limit(20).get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != FirebaseAuth.instance.currentUser?.uid)
          .toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  Future<List<UserModel>> getUsersByLocation(String location) async {
    try {
      // FIX: This query won't work as expected with GeoPoint `location`
      // You cannot directly query a GeoPoint field using `isEqualTo` with a string city name.
      // You should query by `locationName` field instead.
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('locationName', isEqualTo: location) // <--- CHANGED THIS
          .where('isAvailable', isEqualTo: true)
          .limit(15)
          .get();

      List<UserModel> users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      return users;
    } catch (e) {
      print('❌ Error getting users by location: $e');
      return [];
    }
  }

  Stream<List<UserModel>> getPotentialMatches({
    required List<String> userSkillsToTeach,
    required List<String> userSkillsToLearn,
    required String excludeUid,
  }) {
    final skillsToFindTeachersFor = userSkillsToLearn.isEmpty ? ['_NO_SKILL_'] : userSkillsToLearn;
    final skillsToFindLearnersFor = userSkillsToTeach.isEmpty ? ['_NO_SKILL_'] : userSkillsToTeach;

    final Stream<List<UserModel>> teachersStream = skillsToFindTeachersFor.first != '_NO_SKILL_'
        ? _firestore
        .collection('users')
        .where('isAvailable', isEqualTo: true)
        .where('uid', isNotEqualTo: excludeUid)
        .where('skillsToTeach', arrayContainsAny: skillsToFindTeachersFor)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data()!)).toList())
        : Stream.value([]);

    final Stream<List<UserModel>> learnersStream = skillsToFindLearnersFor.first != '_NO_SKILL_'
        ? _firestore
        .collection('users')
        .where('isAvailable', isEqualTo: true)
        .where('uid', isNotEqualTo: excludeUid)
        .where('skillsToLearn', arrayContainsAny: skillsToFindLearnersFor)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data()!)).toList())
        : Stream.value([]);

    return Rx.combineLatest2(teachersStream, learnersStream, (teachers, learners) {
      final Set<UserModel> uniqueUsers = {};
      uniqueUsers.addAll(teachers);
      uniqueUsers.addAll(learners);

      return uniqueUsers.toList().take(5).toList();
    });
  }

  // --- Helper Methods ---

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double _calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadiusKm = 6371.0;

    final lat1Rad = _degreesToRadians(point1.latitude);
    final lon1Rad = _degreesToRadians(point1.longitude);
    final lat2Rad = _degreesToRadians(point2.latitude);
    final lon2Rad = _degreesToRadians(point2.longitude);

    final deltaLat = lat2Rad - lat1Rad;
    final deltaLon = lon2Rad - lon1Rad;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }
}