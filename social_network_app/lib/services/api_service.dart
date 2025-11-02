import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'database_service.dart';

class ApiService {
  // Try different URLs for local development
  static const List<String> baseUrls = [
    'http://localhost:9000/api', // Standard localhost
    'http://172.21.160.167:9000/api', // Alternative localhost
  ];

  final DatabaseService _dbService = DatabaseService();
  String _currentBaseUrl = baseUrls[0];

  Future<List<User>> getUsers() async {
    // Try each base URL until one works
    for (final baseUrl in baseUrls) {
      _currentBaseUrl = baseUrl;
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/users'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 3));

        // Use debugPrint for Flutter (works in debug mode)
        debugPrint('✅ Connected to backend at: $baseUrl');

        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          final users = data.map((json) => User.fromJson(json)).toList();

          await _dbService.insertUsers(users);
          return users;
        }
      } catch (e) {
        debugPrint('❌ Failed to connect to $baseUrl: $e');
        // Try next URL
        continue;
      }
    }

    // If all URLs fail, use cached or sample data
    debugPrint('🔄 Using fallback data');
    final cachedUsers = await _dbService.getUsers();
    if (cachedUsers.isNotEmpty) {
      return cachedUsers;
    }
    return _getSampleUsers();
  }

  Future<List<Recommendation>> getRecommendations(
    int userId,
    int degree,
  ) async {
    // Check cache first
    if (_dbService.hasCachedRecommendations(userId, degree)) {
      final cached = await _dbService.getCachedRecommendations(userId, degree);
      debugPrint('📦 Using cached recommendations');
      return cached;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_currentBaseUrl/recommendations/$userId?degree=$degree',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        final recommendations = data
            .map((json) => Recommendation.fromJson(json))
            .toList();

        await _dbService.cacheRecommendations(userId, degree, recommendations);
        return recommendations;
      }
    } catch (e) {
      debugPrint('❌ Recommendations API error: $e');
    }

    // Fallback to sample data
    debugPrint('🔄 Using sample recommendations');
    return _getSampleRecommendations(userId, degree);
  }

  Future<Map<String, dynamic>> getNetworkData() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_currentBaseUrl/network'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('❌ Network API error: $e');
    }

    // Fallback to sample data
    debugPrint('🔄 Using sample network data');
    return _getSampleNetworkData();
  }

  // Enhanced sample data
  List<User> _getSampleUsers() {
    return [
      User(id: 1, name: "Alice"),
      User(id: 2, name: "Bob"),
      User(id: 3, name: "Charlie"),
      User(id: 4, name: "Diana"),
      User(id: 5, name: "Eve"),
      User(id: 6, name: "Frank"),
      User(id: 7, name: "Grace"),
      User(id: 8, name: "Henry"),
      User(id: 9, name: "Ivy"),
      User(id: 10, name: "Jack"),
    ];
  }

  List<Recommendation> _getSampleRecommendations(int userId, int degree) {
    // More realistic sample data based on user
    switch (userId) {
      case 1: // Alice
        return [
          Recommendation(id: 5, name: "Eve", degree: 2, mutualFriends: 3),
          Recommendation(id: 6, name: "Frank", degree: 2, mutualFriends: 2),
          Recommendation(id: 7, name: "Grace", degree: 3, mutualFriends: 1),
          Recommendation(id: 8, name: "Henry", degree: 2, mutualFriends: 2),
        ];
      case 2: // Bob
        return [
          Recommendation(id: 3, name: "Charlie", degree: 2, mutualFriends: 2),
          Recommendation(id: 9, name: "Ivy", degree: 2, mutualFriends: 1),
          Recommendation(id: 10, name: "Jack", degree: 3, mutualFriends: 1),
        ];
      default:
        return [
          Recommendation(id: 1, name: "Alice", degree: 2, mutualFriends: 2),
          Recommendation(id: 2, name: "Bob", degree: 2, mutualFriends: 1),
          Recommendation(id: 4, name: "Diana", degree: 2, mutualFriends: 1),
        ];
    }
  }

  Map<String, dynamic> _getSampleNetworkData() {
    return {
      "nodes": [
        {"id": 1, "label": "Alice", "name": "Alice"},
        {"id": 2, "label": "Bob", "name": "Bob"},
        {"id": 3, "label": "Charlie", "name": "Charlie"},
        {"id": 4, "label": "Diana", "name": "Diana"},
        {"id": 5, "label": "Eve", "name": "Eve"},
        {"id": 6, "label": "Frank", "name": "Frank"},
        {"id": 7, "label": "Grace", "name": "Grace"},
        {"id": 8, "label": "Henry", "name": "Henry"},
      ],
      "edges": [
        {"from": 1, "to": 2},
        {"from": 1, "to": 3},
        {"from": 1, "to": 4},
        {"from": 2, "to": 5},
        {"from": 2, "to": 6},
        {"from": 3, "to": 7},
        {"from": 4, "to": 8},
        {"from": 5, "to": 6},
        {"from": 7, "to": 8},
      ],
    };
  }

  // Method to check backend connectivity
  Future<bool> checkBackendConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_currentBaseUrl/users'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Helper function for debug printing
void debugPrint(String message) {
  // This will only print in debug mode, not in production
  assert(() {
    (message);
    return true;
  }());
}
