// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/exchange_request.dart';
import '../models/review_model.dart';
import '../models/skill_model.dart';
import '../models/usermodel.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ExchangeRequest>> getExchangeRequests({
    required String userId,
    required bool isReceived,
  }) {
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

  // Current user ka UID get karne ke liye
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

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

  // 1) Get user skills as list (Your existing method - kept as is)
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

  // 2) Add a new skill (Your existing method - enhanced with error handling)
  Future<bool> addUserSkill(String uid, String skillName) async {
    print('🔍 addUserSkill called for uid=$uid, skill="$skillName"');
    try {
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('skills');
      final docRef = await col.add({'name': skillName});
      print('✅ Skill doc created with ID=${docRef.id}');

      // Also update user's main skillsToTeach array for easy searching
      await updateUser(uid, {
        'skillsToTeach': FieldValue.arrayUnion([skillName])
      });

      return true;
    } catch (e) {
      print('❌ addUserSkill error: $e');
      return false;
    }
  }

  // 3) Remove a skill by document ID (Your existing method - enhanced)
  Future<bool> removeUserSkill(String uid, String skillId,
      String skillName) async {
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
  Future<bool> updateAvailability(String uid, bool isAvailable) async {
    return await updateUser(uid, {'isAvailable': isAvailable});
  }

  // Update user rating after skill exchange
  Future<bool> updateUserRating(String uid, double newRating,
      int totalExchanges) async {
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
  Future<bool> createExchangeRequest({
    required String receiverId,
    required String senderSkill,
    required String receiverSkill,
    required String message,
    String? location,
    DateTime? scheduledDate,
  }) async {
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
  Future<bool> updateExchangeStatus(String exchangeId,
      ExchangeStatus status,) async {
    try {
      await _db.collection('exchanges').doc(exchangeId).update({
        'status': status.toString(),
      });
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

      // Create review document
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

      // Start a batch write
      final batch = _db.batch();

      // Add review
      batch.set(docRef, review.toMap());

      // Get user's current rating and total exchanges
      final userDoc = await _db.collection('users').doc(reviewedUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final currentRating = (userData['rating'] ?? 0.0).toDouble();
      final totalExchanges = (userData['totalExchanges'] ?? 0) + 1;

      // Calculate new rating
      final newRating = ((currentRating * (totalExchanges - 1)) + rating) / totalExchanges;

      // Update user's rating and total exchanges
      batch.update(_db.collection('users').doc(reviewedUserId), {
        'rating': newRating,
        'totalExchanges': totalExchanges,
        'reviews': FieldValue.arrayUnion([docRef.id]),
      });

      // Commit the batch
      await batch.commit();
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
}