import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'quiz_progress';

  /// Check if user can play a category now. Enforces a 24-hour cooldown from last play.
  static Future<bool> canPlayCategory(String categoryId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final lastPlayed = await getLastPlayedAt(userId);
      if (lastPlayed == null) return true; // never played

      final nextAllowed = lastPlayed.add(const Duration(hours: 24));
      return DateTime.now().isAfter(nextAllowed);
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

      // Record playedAt as server timestamp and store lastPlayedAt for quick lookup
      await _firestore.collection(_collection).add({
        'userId': userId,
        'categoryId': categoryId,
        'playedAt': FieldValue.serverTimestamp(),
        'lastPlayedAt': FieldValue.serverTimestamp(),
        'results': results,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also update a denormalized field on the user doc for quick access
      await _firestore.collection('users').doc(userId).set({
        'lastQuizPlayedAt': FieldValue.serverTimestamp(),
        'lastQuizCategory': categoryId
      }, SetOptions(merge: true));
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
      final lastPlayed = await getLastPlayedAt(userId);
      if (lastPlayed == null) return null;
      return lastPlayed.add(const Duration(hours: 24));
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
      final lastPlayed = await getLastPlayedAt(userId);
      if (lastPlayed == null) return false;
      return DateTime.now().difference(lastPlayed) < const Duration(hours: 24);
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
      final lastPlayed = await getLastPlayedAt(userId);
      if (lastPlayed == null) return null;

      // Attempt to read denormalized field on user doc
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final cat = userDoc.data()?['lastQuizCategory'] as String?;
        if (cat != null) return cat;
      }

      // Fallback: query the progress collection for the most recent play within 24 hours
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('playedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
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

  /// Get last played timestamp for user (if any) from denormalized user doc or progress collection
  static Future<DateTime?> getLastPlayedAt(String userId) async {
    try {
      // Check user doc first (denormalized)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final ts = userDoc.data()?['lastQuizPlayedAt'];
        if (ts != null) {
          if (ts is Timestamp) return ts.toDate();
          if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
        }
      }

      // Fallback to querying the progress collection
      final query = await _firestore.collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('playedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final playedAt = query.docs.first.data()['playedAt'] as Timestamp?;
        if (playedAt != null) return playedAt.toDate();
      }

      return null;
    } catch (e) {
      print('Error getting lastPlayedAt: $e');
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