import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

class VideoService {
  static final _db = FirebaseFirestore.instance;

  // Stream videos ordered by uploadedAt desc
  static Stream<List<VideoModel>> streamVideos() {
    return _db
        .collection('videos')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => VideoModel.fromDoc(d)).toList());
  }

  // Award reward to user for video completion (ensures single reward per user/video)
  // rewardAmount is in-app points (later map to tokens on chain)
  static Future<bool> awardReward({
    required String uid,
    required String videoId,
    required double rewardAmount,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final earnedRef = userRef.collection('earned').doc(videoId); // per-user record (not a list)
    final rewardsColl = userRef.collection('rewards');

    return _db.runTransaction((tx) async {
      final earnedSnap = await tx.get(earnedRef);
      if (earnedSnap.exists) {
        // already rewarded
        return false;
      }

      // mark as earned
      tx.set(earnedRef, {
        'videoId': videoId,
        'amount': rewardAmount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // update balance
      final userSnap = await tx.get(userRef);
      double currentBalance = 0.0;
      if (userSnap.exists) {
        final d = userSnap.data()!;
        currentBalance = (d['balance'] ?? 0).toDouble();
      } else {
        // create user doc minimally if absent
        tx.set(userRef, {'balance': rewardAmount}, SetOptions(merge: true));
        // also write reward record separately below
      }
      final newBalance = currentBalance + rewardAmount;
      tx.set(userRef, {'balance': newBalance}, SetOptions(merge: true));

      // ledger entry
      tx.set(rewardsColl.doc(), {
        'videoId': videoId,
        'amount': rewardAmount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  static Future<List<VideoModel>> getVideos() async {
    // Test video data
    return [
      VideoModel(
        id: '1',
        title: 'Sample Video',
        description: 'CoinNewsExtra TV Sample Content',
        youtubeId: 'p4kmPtTU4lw',
        reward: 1.0,
        thumbnailUrl: 'https://img.youtube.com/vi/p4kmPtTU4lw/0.jpg',
        durationSeconds: 300,  // Add duration in seconds
      ),
    ];
  }
}
