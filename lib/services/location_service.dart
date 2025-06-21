
import 'dart:convert'; // Import for JSON decoding
import 'package:http/http.dart' as http; // Import the http package
import '../api/secrets.dart'; // Make sure this path is correct

class LocationService {
  Future<String> getCityName(double latitude, double longitude) async {
    print('Attempting to reverse geocode for Lat: $latitude, Lng: $longitude');

    try {
      final String apiKey = kLocationIQAqiKey; // Get your API key
      final String url = 'https://us1.locationiq.com/v1/reverse.php?key=$apiKey&lat=$latitude&lon=$longitude&format=json';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // --- DEBUG PRINTS for raw response ---
        print('LocationIQ Raw API Response (HTTP):');
        print('  DisplayName: ${data['display_name']}');
        print('  Address object null? ${data['address'] == null}');
        // --- END DEBUG PRINTS ---

        final Map<String, dynamic>? address = data['address'];

        if (address != null) {
          // Prioritize fields based on your browser test (town, then city, etc.)
          if (address.containsKey('town') && address['town'] is String && address['town'].isNotEmpty) {
            print('  Found town from raw map: ${address['town']}');
            return address['town'];
          }
          if (address.containsKey('city') && address['city'] is String && address['city'].isNotEmpty) {
            print('  Found city from raw map: ${address['city']}');
            return address['city'];
          }
          if (address.containsKey('suburb') && address['suburb'] is String && address['suburb'].isNotEmpty) {
            print('  Found suburb from raw map: ${address['suburb']}');
            return address['suburb'];
          }
          if (address.containsKey('neighbourhood') && address['neighbourhood'] is String && address['neighbourhood'].isNotEmpty) {
            print('  Found neighbourhood from raw map: ${address['neighbourhood']}');
            return address['neighbourhood'];
          }
          if (address.containsKey('county') && address['county'] is String && address['county'].isNotEmpty) {
            print('  Found county from raw map: ${address['county']}');
            return address['county'];
          }
          if (address.containsKey('state') && address['state'] is String && address['state'].isNotEmpty) {
            print('  Found state from raw map: ${address['state']}');
            return address['state'];
          }
          if (address.containsKey('country') && address['country'] is String && address['country'].isNotEmpty) {
            print('  Found country from raw map: ${address['country']}');
            return address['country'];
          }
        }

        // Fallback to display_name from the raw response
        print('  No specific town/city/etc. found from raw map. Using displayName or "Unknown Location".');
        return data['display_name'] ?? 'Unknown Location';

      } else {
        // Handle API errors (e.g., 403 Forbidden, 401 Unauthorized, 429 Rate Limit)
        print('LocationIQ API Error: Status Code ${response.statusCode}, Body: ${response.body}');
        return 'Unknown Location';
      }

    } catch (e) {
      print('ERROR in getCityName (HTTP Request): $e');
      return 'Unknown Location';
    }
  }
}