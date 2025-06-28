import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;

class FCMService {
  static Future<void> sendPushMessage({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      /// Step 1: Load full service account JSON content
      final fileContent = await rootBundle.loadString('lib/services/firebase/service-account.json');
      final serviceJson = json.decode(fileContent);

      /// Step 2: Extract project ID from raw JSON
      final projectId = serviceJson['project_id'];

      /// Step 3: Authenticate using service account
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);

      /// Step 4: FCM v1 API request
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final message = {
        "message": {
          "token": token,
          "notification": {
            "title": title,
            "body": body,
          },
          "android": {
            "priority": "high"
          },
        }
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      print('✅ FCM Response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('❌ Error sending FCM: $e');
    }
  }
}