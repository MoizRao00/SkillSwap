// lib/services/skill_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

// Note: We don't need the LightcastAuthService for this API
// import 'lightcast_auth_service.dart';

class SkillApiService {
  // Use the GitHub API for topics
  final String _baseUrl = 'https://api.github.com';



  Future<List<String>> searchSkills(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // We don't need a token for this public API
      // final accessToken = await _authService.getAccessToken();

      // The search endpoint for GitHub Topics
      final uri = Uri.parse('$_baseUrl/search/topics?q=$query&per_page=20');

      final response = await http.get(
        uri,
        headers: {
          // GitHub API requires a User-Agent header
          'User-Agent': 'FlutterApp/1.0',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse the list of topics from the GitHub API response
        // The topics are in `items` and each item has a `name`
        final items = data['items'] as List;
        final skills = items.map((item) => item['name'] as String).toList();

        return skills;
      } else {
        // If the request fails, print the error and return an empty list
        print('Error fetching skills: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // Catch any network or parsing errors
      print('Network or parsing error: $e');
      return [];
    }
  }
}