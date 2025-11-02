import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Universal in-memory storage that works on ALL platforms
  final Map<int, User> _userCache = {};
  final Map<String, List<Recommendation>> _recommendationCache = {};

  // User operations
  Future<void> insertUsers(List<User> users) async {
    for (var user in users) {
      _userCache[user.id] = user;
    }

    // If we're NOT on web and want to use SQLite, we could add it here
    // But for simplicity, we'll use in-memory for all platforms
    if (!kIsWeb) {
      debugPrint('📱 Running on mobile - could use SQLite here');
    } else {
      debugPrint('🌐 Running on web - using in-memory storage');
    }
  }

  Future<List<User>> getUsers() async {
    return _userCache.values.toList();
  }

  // Recommendation caching
  Future<void> cacheRecommendations(
    int userId,
    int degree,
    List<Recommendation> recommendations,
  ) async {
    final cacheKey = '$userId-$degree';
    _recommendationCache[cacheKey] = recommendations;
  }

  Future<List<Recommendation>> getCachedRecommendations(
    int userId,
    int degree,
  ) async {
    final cacheKey = '$userId-$degree';
    return _recommendationCache[cacheKey] ?? [];
  }

  Future<void> close() async {
    // Cleanup if needed
    _userCache.clear();
    _recommendationCache.clear();
  }

  // Helper to check if we have data
  bool hasCachedUsers() {
    return _userCache.isNotEmpty;
  }

  bool hasCachedRecommendations(int userId, int degree) {
    final cacheKey = '$userId-$degree';
    return _recommendationCache.containsKey(cacheKey) &&
        _recommendationCache[cacheKey]!.isNotEmpty;
  }
}

// Helper function for debug printing
void debugPrint(String message) {
  // This will only print in debug mode, not in production
  assert(() {
    debugPrint(message);
    return true;
  }());
}
