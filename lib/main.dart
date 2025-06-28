import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/firestore_service.dart';
import 'app.dart';
import 'firebase_options.dart';  // Add this import



@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

Future<void> initFCM() async {
  try {
    // Set background message handler first
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Request permission
    final messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        print('Token saved to Firestore');
      }
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📬 Received a foreground FCM message');
      print('Message data: ${message.data}');

      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'high_importance_channel', // must match your AndroidManifest channel ID
          'SkillSwap Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

        const NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
        );

        await flutterLocalNotificationsPlugin.show(
          0, // notification ID
          notification.title,
          notification.body,
          platformDetails,
        );
      }
    });

  } catch (e) {
    print('Error initializing FCM: $e');
  }
}

Future<void> initializeApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    await initFCM();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('📱 Current user: ${currentUser.uid}');

      final userDocExists = await FirestoreService().ensureUserDocumentExists();
      if (!userDocExists) {
        print('⚠️ Warning: Failed to ensure user document exists');
      } else {
        print('✅ User document verified/created');
      }
    } else {
      print('ℹ️ No user currently logged in');
    }
  } catch (e) {
    print('❌ Error during initialization: $e');
    rethrow;
  }
}
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeApp();
    runApp(const App());
  } catch (e) {
    print('❌ Fatal error during app startup: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}