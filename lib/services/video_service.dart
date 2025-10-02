import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';
import '../data/video_data.dart';

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
    try {
      // Get videos from Firebase Firestore
      final querySnapshot = await _db
          .collection('videos')
          .where('isActive', isEqualTo: true)
          .orderBy('uploadedAt', descending: true)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // Auto-populate Firebase if empty
        print('🎥 Auto-populating video database...');
        await _populateVideosCollection();
        
        // Try again after population
        final retrySnapshot = await _db
            .collection('videos')
            .where('isActive', isEqualTo: true)
            .orderBy('uploadedAt', descending: true)
            .get();
        
        if (retrySnapshot.docs.isNotEmpty) {
          return retrySnapshot.docs.map((doc) {
            return VideoModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        }
        
        // Fallback to static data if population failed
        print('⚠️ Firebase population failed, using static data');
        return VideoData.getAllVideos();
      }
      
      return querySnapshot.docs.map((doc) {
        return VideoModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error fetching videos from Firebase: $e');
      // Fallback to static data on error
      return VideoData.getAllVideos();
    }
  }

  /// Auto-populate videos collection if empty
  static Future<void> _populateVideosCollection() async {
    try {
      final batch = _db.batch();
      final staticVideos = VideoData.getAllVideos();
      
      for (final video in staticVideos) {
        final videoRef = _db.collection('videos').doc(video.id);
        batch.set(videoRef, {
          'id': video.id,
          'youtubeId': video.youtubeId,
          'url': video.youtubeWatchUrl,
          'title': video.title,
          'subtitle': video.subtitle ?? '',
          'thumbnailUrl': video.thumbnailUrl,
          'duration': video.duration ?? '',
          'views': video.views ?? '',
          'uploadTime': video.uploadTime ?? '',
          'channelName': video.channelName ?? 'CoinNews Extra',
          'description': video.description,
          'category': _extractCategory(video.title),
          'isActive': true,
          'uploadedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('✅ Successfully populated ${staticVideos.length} videos to Firebase');
    } catch (e) {
      print('❌ Error populating videos collection: $e');
    }
  }

  /// Extract category from video title for organization
  static String _extractCategory(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('bitcoin')) return 'bitcoin';
    if (lowerTitle.contains('defi')) return 'defi';
    if (lowerTitle.contains('nft')) return 'nft';
    if (lowerTitle.contains('blockchain')) return 'education';
    if (lowerTitle.contains('market') || lowerTitle.contains('analysis')) return 'market-analysis';
    return 'general';
  }

  /// Generate YouTube thumbnail URL from video ID
  static String getYoutubeThumbnailUrl(String videoId, {String quality = 'hqdefault'}) {
    if (videoId.isEmpty) return '';
    
    // Available qualities: default, mqdefault, hqdefault, sddefault, maxresdefault
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  /// Generate high resolution YouTube thumbnail URL
  static String getHighResThumbnailUrl(String videoId) {
    return getYoutubeThumbnailUrl(videoId, quality: 'maxresdefault');
  }

  /// Generate medium resolution YouTube thumbnail URL
  static String getMediumResThumbnailUrl(String videoId) {
    return getYoutubeThumbnailUrl(videoId, quality: 'mqdefault');
  }

  /// Generate YouTube watch URL from video ID
  static String getYoutubeWatchUrl(String videoId) {
    if (videoId.isEmpty) return '';
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  /// Extract video ID from various YouTube URL formats
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;

    // Handle youtu.be format
    if (url.contains('youtu.be/')) {
      final match = RegExp(r'youtu\.be\/([a-zA-Z0-9_-]+)').firstMatch(url);
      return match?.group(1);
    }

    // Handle youtube.com/watch format
    if (url.contains('youtube.com/watch')) {
      final match = RegExp(r'[?&]v=([a-zA-Z0-9_-]+)').firstMatch(url);
      return match?.group(1);
    }

    // Handle youtube.com/embed format
    if (url.contains('youtube.com/embed/')) {
      final match = RegExp(r'embed\/([a-zA-Z0-9_-]+)').firstMatch(url);
      return match?.group(1);
    }

    // If it's already just an ID
    if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(url) && url.length == 11) {
      return url;
    }

    return null;
  }

  /// Validate YouTube video ID format
  static bool isValidVideoId(String videoId) {
    if (videoId.isEmpty || videoId.length != 11) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(videoId);
  }

  /// Get video thumbnail with fallback options
  static String getThumbnailWithFallback(VideoModel video) {
    // Try the video's specific thumbnail first
    if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty) {
      return video.thumbnailUrl!;
    }
    
    // Fallback to YouTube thumbnail
    if (video.youtubeId.isNotEmpty) {
      return getYoutubeThumbnailUrl(video.youtubeId);
    }
    
    // Final fallback to a placeholder or empty string
    return '';
  }
}
