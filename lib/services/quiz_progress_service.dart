import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'quiz_progress';

  /// Check if user can play ANY category today (one category per day total)
  static Future<bool> canPlayCategory(String categoryId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Check if user has played ANY category today
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('playedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('playedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      return query.docs.isEmpty; // Can play if no category was played today
    } catch (e) {
      print('Error checking category availability: $e');
      return false;
    }
  }

  /// Record that user played a category today
  static Future<void> recordCategoryPlay(String categoryId, Map<String, dynamic> results) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection(_collection).add({
        'userId': userId,
        'categoryId': categoryId,
        'playedAt': FieldValue.serverTimestamp(),
        'results': results,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording category play: $e');
      rethrow;
    }
  }

  /// Get when user can next play (any category)
  static Future<DateTime?> getNextPlayTime(String categoryId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Check when user last played ANY category today
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('playedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('playedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('playedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final lastPlay = query.docs.first.data()['playedAt'] as Timestamp;
        final lastPlayDate = lastPlay.toDate();
        final nextPlayDate = DateTime(
          lastPlayDate.year,
          lastPlayDate.month,
          lastPlayDate.day + 1,
        );
        return nextPlayDate;
      }

      return null; // Can play now
    } catch (e) {
      print('Error getting next play time: $e');
      return null;
    }
  }

  /// Check if user has played any category today
  static Future<bool> hasPlayedToday() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('playedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('playedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if played today: $e');
      return false;
    }
  }

  /// Get which category was played today (if any)
  static Future<String?> getTodayPlayedCategory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('playedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('playedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('playedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['categoryId'] as String?;
      }

      return null;
    } catch (e) {
      print('Error getting today played category: $e');
      return null;
    }
  }

  /// Get user's category play statistics
  static Future<Map<String, int>> getCategoryPlayCounts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, int> counts = {};
      for (final doc in query.docs) {
        final categoryId = doc.data()['categoryId'] as String;
        counts[categoryId] = (counts[categoryId] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting category play counts: $e');
      return {};
    }
  }
}