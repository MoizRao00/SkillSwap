// lib/services/firestore_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
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
import 'fcm_services.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeoHasher _geoHasher = GeoHasher();

  FirestoreService._privateConstructor();
  static final FirestoreService _instance = FirestoreService._privateConstructor();
  factory FirestoreService() {
    return _instance;
  }

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

   // Notfication

  Future<void> sendNotificationToUser(
      {
    required String userId,
    required String title,
    required String body,
  })
  async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        await FCMService.sendPushMessage(
          token: fcmToken,
          title: title,
          body: body,
        );
      } else {
        print('⚠️ No FCM token found for user: $userId');
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // For Exchange Requests
  Future<void> sendExchangeNotification(ExchangeRequest request) async {
    switch (request.status) {
      case ExchangeStatus.pending:
        await sendNotificationToUser(
          userId: request.receiverId,
          title: 'New Exchange Request',
          body: 'Someone wants to exchange ${request.senderSkill} for ${request.receiverSkill}',
        );
        break;

      case ExchangeStatus.accepted:
        await sendNotificationToUser(
          userId: request.senderId,
          title: 'Request Accepted',
          body: 'Your exchange request has been accepted!',
        );
        break;

      case ExchangeStatus.completed:
      // Notify both parties
        await Future.wait([
          sendNotificationToUser(
            userId: request.senderId,
            title: 'Exchange Completed',
            body: 'Your exchange has been completed successfully!',
          ),
          sendNotificationToUser(
            userId: request.receiverId,
            title: 'Exchange Completed',
            body: 'Your exchange has been completed successfully!',
          ),
        ]);
        break;

      default:
        break;
    }
  }

  // For Chat Messages
  Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String message,
  })
  async {
    await sendNotificationToUser(
      userId: receiverId,
      title: 'New Message from $senderName',
      body: message,
    );
  }

  // For Reviews
  Future<void> sendReviewNotification({
    required String userId,
    required double rating,
  })
  async {
    await sendNotificationToUser(
      userId: userId,
      title: 'New Review Received',
      body: 'You received a ${rating.toStringAsFixed(1)} star review!',
    );
  }

  // Exchange Request Methods ---
  Stream<ExchangeRequest> getExchangeStream(String exchangeId) {
    return _firestore
        .collection('exchanges')
        .doc(exchangeId)
        .snapshots()
        .map((doc) => ExchangeRequest.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    ));
  }

  Future<bool> sendExchangeRequest({
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

      // Check for duplicates
      final duplicateCheck = await _firestore
          .collection('exchanges')
          .where('senderId', isEqualTo: sender.uid)
          .where('receiverId', isEqualTo: receiverId)
          .where('senderSkill', isEqualTo: senderSkill)
          .where('receiverSkill', isEqualTo: receiverSkill)
          .where('status', whereIn: ['pending', 'accepted', 'confirmedBySender', 'confirmedByReceiver'])
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        print("⚠️ Duplicate request detected");
        return false;
      }

      // Create exchange request
      final docRef = _firestore.collection('exchanges').doc();
      final batch = _firestore.batch();

      final exchangeData = {
        'senderId': sender.uid,
        'receiverId': receiverId,
        'senderSkill': senderSkill,
        'receiverSkill': receiverSkill,
        'status': ExchangeStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'location': location?.isEmpty ?? true ? null : location,
        'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate) : null,
      };

      batch.set(docRef, exchangeData);

      // Add message if provided
      if (message.isNotEmpty) {
        final messageRef = docRef.collection('messages').doc();
        final messageData = {
          'senderId': sender.uid,
          'text': message.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        };
        batch.set(messageRef, messageData);
      }

      // Create notification
      final notificationRef = _firestore.collection('notifications').doc();
      final notificationData = {
        'userId': receiverId,
        'title': 'New Exchange Request',
        'message': 'Someone wants to exchange ${senderSkill} for ${receiverSkill}',
        'type': NotificationType.exchangeRequest.name,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': {
          'exchangeId': docRef.id,
          'senderId': sender.uid,
          'senderSkill': senderSkill,
          'receiverSkill': receiverSkill,
        },
      };
      batch.set(notificationRef, notificationData);

      await batch.commit();
      return true;
    } catch (e) {
      print('❌ sendExchangeRequest error: $e');
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

        ...sent.docs.map((doc) => ExchangeRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id)),

        ...received.docs.map((doc) => ExchangeRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id)),
      ];

      return requests..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<bool> updateExchangeStatus(String exchangeId, ExchangeStatus newStatus) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final docRef = _firestore.collection('exchanges').doc(exchangeId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final currentStatus = data['status'] as String;
      final senderId = data['senderId'] as String;
      final receiverId = data['receiverId'] as String;

      String updateTo = newStatus.name;

      // Handle completion logic
      if (newStatus == ExchangeStatus.completed) {
        if (currentStatus == ExchangeStatus.accepted.name) {
          updateTo = currentUserId == senderId
              ? ExchangeStatus.confirmedBySender.name
              : ExchangeStatus.confirmedByReceiver.name;
        } else if (currentStatus == ExchangeStatus.confirmedBySender.name &&
            currentUserId == receiverId) {
          updateTo = ExchangeStatus.completed.name;
          await _updateExchangeCompletion(senderId, receiverId);
        } else if (currentStatus == ExchangeStatus.confirmedByReceiver.name &&
            currentUserId == senderId) {
          updateTo = ExchangeStatus.completed.name;
          await _updateExchangeCompletion(senderId, receiverId);
        }
      }

      await docRef.update({'status': updateTo});

      // Create notifications based on status change
      if (updateTo == ExchangeStatus.confirmedBySender.name) {
        await createNotification(
          userId: receiverId,
          title: 'Exchange Completion Requested',
          message: 'The sender has marked the exchange as complete. Please confirm if you agree.',
          type: NotificationType.exchangeRequest,
          data: {'exchangeId': exchangeId},
        );
      } else if (updateTo == ExchangeStatus.confirmedByReceiver.name) {
        await createNotification(
          userId: senderId,
          title: 'Exchange Completion Requested',
          message: 'The receiver has marked the exchange as complete. Please confirm if you agree.',
          type: NotificationType.exchangeRequest,
          data: {'exchangeId': exchangeId},
        );
      } else if (updateTo == ExchangeStatus.completed.name) {
        // Notify both parties
        await Future.wait([
          createNotification(
            userId: senderId,
            title: 'Exchange Completed',
            message: 'Your exchange has been completed successfully!',
            type: NotificationType.exchangeCompleted,
            data: {'exchangeId': exchangeId},
          ),
          createNotification(
            userId: receiverId,
            title: 'Exchange Completed',
            message: 'Your exchange has been completed successfully!',
            type: NotificationType.exchangeCompleted,
            data: {'exchangeId': exchangeId},
          ),
        ]);
      } else if (updateTo == ExchangeStatus.accepted.name) {
        await createNotification(
          userId: senderId,
          title: 'Exchange Request Accepted',
          message: 'Your exchange request has been accepted!',
          type: NotificationType.exchangeAccepted,
          data: {'exchangeId': exchangeId},
        );
      }
      final exchange = await _firestore.collection('exchanges').doc(exchangeId).get();
      if (exchange.exists) {
        final request = ExchangeRequest.fromMap(
          exchange.data() as Map<String, dynamic>,
          exchange.id,
        );
        await sendExchangeNotification(request);
      }

      return true;
    } catch (e) {
      print('❌ Error updating exchange status: $e');
      return false;
    }
  }
// Helper method for exchange completion
  Future<void> _updateExchangeCompletion(String senderId, String receiverId) async {
    final batch = _firestore.batch();

    // Update sender's stats
    final senderRef = _firestore.collection('users').doc(senderId);
    batch.update(senderRef, {
      'totalExchanges': FieldValue.increment(1),
    });

    // Update receiver's stats
    final receiverRef = _firestore.collection('users').doc(receiverId);
    batch.update(receiverRef, {
      'totalExchanges': FieldValue.increment(1),
    });

    await batch.commit();
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

  Future<void> deleteExchange(String exchangeId) async {
    final exchangeRef = _firestore.collection('exchanges').doc(exchangeId);

    // Use a WriteBatch to perform multiple deletions atomically
    final batch = _firestore.batch();

    // 1. Delete all messages in the subcollection
    final messagesSnapshot = await exchangeRef.collection('messages').get();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete the main exchange document
    batch.delete(exchangeRef);

    // Commit the batch to run all deletes
    await batch.commit();
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
  Future<bool> ensureUserDocumentExists() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        print('Creating user document for ${currentUser.uid}');
        await createUserDocument(
          currentUser.uid,
          currentUser.displayName ?? 'New User',
          currentUser.email ?? '',
        );
        return true;
      }

      return true;
    } catch (e) {
      print('❌ Error ensuring user document exists: $e');
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
      'locationName': null,
      'skillsToTeach': [],
      'skillsToLearn': [],
      'rating': 0.0,
      'totalReviews': 0,
      'totalExchanges': 0,
      'reviews': [],
      'createdAt': Timestamp.fromDate(now),
      'lastActive': Timestamp.fromDate(now),
      'isAvailable': true,
      'isVerified': false,
      'portfolio': [],
    });
    print('✅ User document created/updated in Firestore for UID: $uid');
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

  Future<bool> sendMessage(String exchangeId, String text) async {
    try {
      final sender = FirebaseAuth.instance.currentUser;
      if (sender == null) return false;

      final docRef = _firestore
          .collection('exchanges')
          .doc(exchangeId)
          .collection('messages')
          .doc();

      final chatMessage = ChatMessage(
        id: docRef.id,
        exchangeId: exchangeId,
        senderId: sender.uid,
        text: text,
        timestamp: DateTime.now(),
      );

      await docRef.set(chatMessage.toMap());

      // Get exchange details
      final exchangeDoc = await _firestore.collection('exchanges').doc(exchangeId).get();
      final exchangeData = exchangeDoc.data();

      if (exchangeData != null) {
        final receiverId = sender.uid == exchangeData['senderId']
            ? exchangeData['receiverId']
            : exchangeData['senderId'];

        // Send notification
        await sendChatNotification(
          receiverId: receiverId,
          senderName: sender.displayName ?? 'sender',
          message: text,
        );
      }

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
        .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>, doc.id)) // ⭐ Pass map and doc.id separately
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
            ExchangeRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id)) // ⭐ Corrected call
            .toList());
  }
  Future<bool> submitReview({
    required String exchangeId,
    required String reviewedUserId,
    required double rating,
    required String comment,
  }) async {
    try {
      final reviewer = FirebaseAuth.instance.currentUser;
      if (reviewer == null || comment.trim().length < 10) return false;

      // ... rest of your code ...

      await sendReviewNotification(
        userId: reviewedUserId,
        rating: rating,
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
      final notificationData = {
        'id': docRef.id,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.toString(), // Using toString() to match your model
        'timestamp': DateTime.now().toIso8601String(), // Using ISO string format
        'isRead': false,
        'data': data,
      };

      print('DEBUG: Creating notification: $notificationData');
      await docRef.set(notificationData);
      print('✅ Notification created successfully');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    print('DEBUG: Fetching notifications for user: $userId');

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          print('DEBUG: Processing notification: ${doc.id}');
          return NotificationModel.fromMap(data);
        }).toList();
      } catch (e) {
        print('❌ Error processing notifications: $e');
        return <NotificationModel>[];
      }
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      print('DEBUG: Marking notification as read: $notificationId');
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});  // Using 'isRead' consistently
      print('✅ Notification marked as read');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // NEWLY ADDED METHOD
  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    if (notifications.docs.isNotEmpty) {
      await batch.commit();
      print('✅ Marked ${notifications.docs.length} notifications as read.');
    } else {
      print('⚠️ No unread notifications found.');
    }
  }



  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      print('✅ FCM Token saved successfully for user: $userId');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  Future<void> verifyFCMSetup() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in to verify FCM');
        return;
      }

      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('Current FCM Token: $fcmToken');

      // Check if token is saved in Firestore
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final savedToken = userDoc.data()?['fcmToken'];

      if (savedToken == fcmToken) {
        print('✅ FCM Token verified and matched in Firestore');
      } else {
        print('⚠️ FCM Token mismatch, updating...');
        await saveFCMToken(currentUser.uid, fcmToken!);
      }
    } catch (e) {
      print('❌ Error verifying FCM setup: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      print('DEBUG: Deleting notification: $notificationId');
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('✅ Notification deleted');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }
  // --- Activity Methods ---

  Stream<List<Activity>> getUserActivities(String userId) {
    print('DEBUG: Fetching activities for user: $userId');

    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          print('DEBUG: Processing activity: ${doc.id}');
          return Activity.fromMap(data);
        }).toList();
      } catch (e) {
        print('❌ Error processing activities: $e');
        print('❌ Error stack trace: ${StackTrace.current}');
        return <Activity>[];
      }
    });
  }

  Future<void> createActivity({
    required String userId,
    required ActivityType type,
    required String title,
    required String description,
    required Map<String, dynamic> data,
  })
  async {
    try {
      final docRef = _firestore.collection('activities').doc();
      final activityData = {
        'id': docRef.id,
        'userId': userId,
        'type': type.toString(),
        'title': title,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data,
        'isRead': false,
      };

      print('DEBUG: Creating activity: $activityData');
      await docRef.set(activityData);
      print('✅ Activity created successfully');
    } catch (e) {
      print('❌ Error creating activity: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
    }
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