// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_model.dart';
import '../models/chat_message.dart';
import '../models/exchange_request.dart';
import '../models/notification_model.dart';
import '../models/potfolio_item.dart';
import '../models/review_model.dart';
import '../models/skill_model.dart';
import '../models/usermodel.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Current user ka UID get karne ke liye
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<ExchangeRequest>> getExchangeRequests({
    required String userId,
    required bool isReceived,
  })
  {
    return _db
        .collection('exchanges')
        .where(isReceived ? 'receiverId' : 'senderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            ExchangeRequest.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Add this to your FirestoreService class
  Future<bool> createInitialUserProfile(User firebaseUser) async {
    try {
      // Check if user already exists
      final exists = await userExists(firebaseUser.uid);
      if (exists) {
        print('✅ User profile already exists');
        return true;
      }

      // Create new UserModel with initial data
      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'New User',
        skillsToTeach: [],
        skillsToLearn: [],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Save to Firestore
      return await saveUser(newUser);
    } catch (e) {
      print('❌ Error creating initial profile: $e');
      return false;
    }
  }

  // ================== USER OPERATIONS (Updated) ==================

  // Save user to Firestore - Updated for UserModel
  Future<bool> saveUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
      print('✅ User saved successfully: ${user.name}');
      return true;
    } catch (e) {
      print('❌ Error saving user: $e');
      return false;
    }
  }

  // Get user from Firestore - Updated for UserModel
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
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

  // Get current logged-in user
  Future<UserModel?> getCurrentUser() async {
    if (currentUserId != null) {
      return await getUser(currentUserId!);
    }
    return null;
  }

  // Update user data
  Future<bool> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      // Last active time bhi update kar rahe hain
      updates['lastActive'] = DateTime.now().toIso8601String();

      await _db.collection('users').doc(uid).update(updates);
      print('✅ User updated successfully: $uid');
      return true;
    } catch (e) {
      print('❌ Error updating user: $e');
      return false;
    }
  }

  //  Get user skills as list (Your existing method - kept as is)
  Future<List<Skill>> getUserSkills(String uid) async {
    try {
      final snap = await _db.collection('users')
          .doc(uid)
          .collection('skills')
          .get();
      return snap.docs
          .map((doc) => Skill.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting user skills: $e');
      return [];
    }
  }

  //  Add a new skill (Your existing method - enhanced with error handling)
  Future<bool> addUserSkill(String uid, String skillName) async {
    print('🔍 addUserSkill called for uid=$uid, skill="$skillName"');
    try {
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('skills');
      final docRef = await col.add({'name': skillName});
      print('✅ Skill doc created with ID=${docRef.id}');

      // Update main skillsToTeach array
      await updateUser(uid, {
        'skillsToTeach': FieldValue.arrayUnion([skillName])
      });

      // Create activity
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

  Future<void> createUserDocument(String uid, String name, String email) async {
    final now = DateTime.now();
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'profilePicUrl': null, // Default empty
      'bio': '',             // Default empty
      'phone': null,
      'location': null,
      'skillsToTeach': [],   // Default empty list
      'skillsToLearn': [],   // Default empty list
      'rating': 0.0,         // Default rating
      'totalExchanges': 0,   // Default total exchanges
      'reviews': [],         // Default empty list
      'createdAt': now.toIso8601String(), // Store as ISO String
      'lastActive': now.toIso8601String(), // Store as ISO String
      'isAvailable': true,   // Default available
      'isVerified': false,   // Default not verified
      'portfolio': [],       // Default empty list
    });
  }


  //  Remove a skill by document ID (Your existing method - enhanced)
  Future<bool> removeUserSkill(String uid, String skillId,
      String skillName)
  async {
    try {
      // Remove from subcollection
      await _db.collection('users')
          .doc(uid)
          .collection('skills')
          .doc(skillId)
          .delete();

      // Also remove from main skillsToTeach array
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

  // ================== NEW SEARCH & QUERY OPERATIONS ==================

  // Search users by skill they can teach
  Future<List<UserModel>> searchUsersBySkill(String skill) async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('users')
          .where('skillsToTeach', arrayContains: skill)
          .where('isAvailable', isEqualTo: true)
          .limit(20)
          .get();

      List<UserModel> users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      print('✅ Found ${users.length} users with skill: $skill');
      return users;
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  // Get users by location
  Future<List<UserModel>> getUsersByLocation(String location) async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('users')
          .where('location', isEqualTo: location)
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

  // ================== REAL-TIME STREAMS ==================

  // Real-time user data stream
  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Real-time skills stream for a user
  Stream<List<Skill>> getUserSkillsStream(String uid) {
    return _db.collection('users')
        .doc(uid)
        .collection('skills')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => Skill.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ================== HELPER METHODS ==================

  // Update user availability
  Future<void> updateAvailability(String uid, bool isAvailable) async {
    await _db.collection('users').doc(uid).update({
      'isAvailable': isAvailable,
      'lastActive': DateTime.now().toIso8601String(), // Update last active
    });
  }
  // Update user rating after skill exchange
  Future<bool> updateUserRating(String uid, double newRating,
      int totalExchanges)
  async {
    return await updateUser(uid, {
      'rating': newRating,
      'totalExchanges': totalExchanges,
    });
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  // Sync skills from subcollection to main user document (one-time migration)
  Future<void> syncUserSkills(String uid) async {
    try {
      // Get skills from subcollection
      List<Skill> skills = await getUserSkills(uid);
      List<String> skillNames = skills.map((skill) => skill.name).toList();

      // Update main user document
      await updateUser(uid, {
        'skillsToTeach': skillNames,
      });

      print('✅ Skills synced for user: $uid');
    } catch (e) {
      print('❌ Error syncing skills: $e');
    }
  }


  // Add these methods to your FirestoreService class

  // Create new exchange request
  Future<bool> createExchangeRequest(
      {
    required String receiverId,
    required String senderSkill,
    required String receiverSkill,
    required String message,
    String? location,
    DateTime? scheduledDate,
  })
  async {
    try {
      final sender = FirebaseAuth.instance.currentUser;
      if (sender == null) return false;

      final docRef = _db.collection('exchanges').doc();
      final request = ExchangeRequest(
        id: docRef.id,
        senderId: sender.uid,
        receiverId: receiverId,
        senderSkill: senderSkill,
        receiverSkill: receiverSkill,
        message: message,
        createdAt: DateTime.now(),
        location: location,
        scheduledDate: scheduledDate,
      );

      await docRef.set(request.toMap());

      // Create activity for receiver
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


  // Get user's exchange requests (both sent and received)
  Stream<List<ExchangeRequest>> getUserExchangeRequests() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('exchanges')
        .where('senderId', isEqualTo: userId)
        .snapshots()
        .asyncMap((sent) async {
      final received = await _db
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

  // Update exchange request status
  Future<bool> updateExchangeStatus(
      String exchangeId,
      ExchangeStatus status,
      )
  async {
    try {
      await _db.collection('exchanges').doc(exchangeId).update({
        'status': status.toString(),
      });

      // Get exchange details
      final exchange = await _db.collection('exchanges').doc(exchangeId).get();
      final exchangeData = exchange.data();
      if (exchangeData == null) return true;

      // Create appropriate activity based on status
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
        // Create activity for both users
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
            type: ActivityType.exchangeRequest,
            title: 'Exchange Request Declined',
            description: 'Your exchange request was declined',
            data: {
              'exchangeId': exchangeId,
              'receiverId': exchangeData['receiverId'],
            },
          );
          break;

        default:
          break;
      }

      return true;
    } catch (e) {
      print('❌ Error updating exchange status: $e');
      return false;
    }
  }

  // Send a message
  Future<bool> sendMessage(String exchangeId, String message) async {
    try {
      final sender = FirebaseAuth.instance.currentUser;
      if (sender == null) return false;

      final docRef = _db  // Changed from FirebaseFirestore.instance to _db
          .collection('exchanges')
          .doc(exchangeId)
          .collection('messages')
          .doc();

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

  // Get messages stream for an exchange
  Stream<List<ChatMessage>> getMessages(String exchangeId) {
    return _db  // Changed from FirebaseFirestore.instance to _db
        .collection('exchanges')
        .doc(exchangeId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String exchangeId, String currentUserId) async {
    try {
      final messagesQuery = await _db  // Changed from FirebaseFirestore.instance to _db
          .collection('exchanges')
          .doc(exchangeId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();  // Changed from FirebaseFirestore.instance to _db
      for (var doc in messagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }
  // Add these methods to your FirestoreService class

  // Submit a review
  Future<bool> submitReview({
    required String exchangeId,
    required String reviewedUserId,
    required double rating,
    required String comment,
  }) async {
    try {
      final reviewer = FirebaseAuth.instance.currentUser;
      if (reviewer == null) return false;

      final docRef = _db.collection('reviews').doc();
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

      // Create activity for reviewed user
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

  // Get reviews for a user
  Stream<List<Review>> getUserReviews(String userId) {
    return _db
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
      final snapshot = await _db
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
  // Add to FirestoreService class

  Stream<List<UserModel>> getNearbyUsers() {
    // Implement based on user's location
    return _db
        .collection('users')
        .where('isAvailable', isEqualTo: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList());
  }

  Stream<List<UserModel>> getPotentialMatches() {
    // Implement based on user's skills
    return _db
        .collection('users')
        .where('isAvailable', isEqualTo: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList());
  }

  Stream<List<dynamic>> getRecentActivities() {
    // Implement based on your activity tracking
    return Stream.value([]); // Placeholder
  }

  // Create a new activity
  Future<void> createActivity({
    required String userId,
    required ActivityType type,
    required String title,
    required String description,
    required Map<String, dynamic> data,
  })
  async {
    try {
      final docRef = _db.collection('activities').doc();
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

  // Get user's activities stream
  Stream<List<Activity>> getUserActivities(String userId) {
    return _db
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Activity.fromMap(doc.data()))
        .toList());
  }

  // Mark activity as read
  Future<void> markActivityAsRead(String activityId) async {
    try {
      await _db
          .collection('activities')
          .doc(activityId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking activity as read: $e');
    }
  }
  // In FirestoreService class

  // Portfolio methods
  Stream<List<PortfolioItem>> getUserPortfolio(String userId) {
    return _db
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
      })
  async {
    try {
      final docRef = _db
          .collection('users')
          .doc(userId)
          .collection('portfolio')
          .doc();

      final item = PortfolioItem(
        id: docRef.id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        date: DateTime.now(),
        tags: tags,
      );

      await docRef.set(item.toMap());

      // Create activity
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
      await _db
          .collection('users')
          .doc(userId)
          .collection('portfolio')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('❌ Error deleting portfolio item: $e');
    }
  }
// Add these methods to your FirestoreService class if they don't exist

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
    return _db.collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data != null && data['skillsToLearn'] != null) {
        return (data['skillsToLearn'] as List)
            .map((skill) => Skill(id: skill, name: skill))
            .toList();
      }
      return <Skill>[];
    });
  }
// Add these methods to your FirestoreService class

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic> data = const {},
  }) async
  {
    try {
      final docRef = _db.collection('notifications').doc();
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

  // Get user's notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data()))
        .toList());
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId)
  async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }
// In lib/services/firestore_service.dart

// Add this method to your FirestoreService class
  Future<List<UserModel>> searchUsers({
    required String query,
    required bool searchSkills,
    String skillType = 'teaching',
    double minRating = 0.0,
    bool onlyAvailable = true,
  })
  async {
    try {
      Query usersQuery = _db.collection('users');

      // Apply availability filter
      if (onlyAvailable) {
        usersQuery = usersQuery.where('isAvailable', isEqualTo: true);
      }

      // Apply rating filter
      if (minRating > 0) {
        usersQuery = usersQuery.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // Apply search filter
      if (searchSkills) {
        // Search by skills
        final field = skillType == 'teaching' ? 'skillsToTeach' : 'skillsToLearn';
        usersQuery = usersQuery.where(field, arrayContains: query.toLowerCase());
      } else {
        // Search by location
        final lowercaseQuery = query.toLowerCase();
        usersQuery = usersQuery
            .where('location', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('location', isLessThan: lowercaseQuery + 'z');
      }

      // Get results
      final snapshot = await usersQuery.limit(20).get();

      // Convert to UserModel list
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != FirebaseAuth.instance.currentUser?.uid) // Exclude current user
          .toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  Future<List<String>> getPopularSkills() async {
    try {
      final snapshot = await _db.collection('users').limit(50).get();
      final skills = <String>{};

      for (var doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.data());
        skills.addAll(user.skillsToTeach);
        skills.addAll(user.skillsToLearn);
      }

      return skills.toList()..sort();
    } catch (e) {
      print('❌ Error getting popular skills: $e');
      return [];
    }
  }

  Future<List<String>> getLocations() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('location', isNull: false)
          .limit(50)
          .get();

      final locations = <String>{};

      for (var doc in snapshot.docs) {
        final location = doc.data()['location'] as String?;
        if (location != null) {
          locations.add(location);
        }
      }

      return locations.toList()..sort();
    } catch (e) {
      print('❌ Error getting locations: $e');
      return [];
    }
  }
  // In FirestoreService class

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _db.batch();
      final notifications = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }
}
