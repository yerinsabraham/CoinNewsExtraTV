import 'package:flutter/foundation.dart';

class LiveVideoConfig {
  // Updated to the requested live video
  static const String primaryLiveStreamId = '5vQPzJqumPk';
  static const String primaryLiveStreamUrl = 'https://www.youtube.com/live/5vQPzJqumPk?si=iWXiifI5XTITy7bG';
  static const String liveStreamTitle = 'CoinNewsExtra Live Stream';
  static const String liveStreamDescription = 'Latest crypto news and market analysis';
  
  // Reward requirement: 10 minutes continuous watching (600 seconds)
  static const int requiredWatchTimeSeconds = 600; // 10 minutes
  static const double watchReward = 7.0; // CNE tokens for Live TV watching (1-10K tier)
  
  // Auto-play behavior: start immediately when entering Live TV page
  static const bool autoPlayOnLaunch = true;
  
  // Stream configuration
  static const bool isLiveStream = true;
  static const bool enableCaptions = true;
  static const bool allowFullscreen = true;

  // In-house promotion banner (thin) — configurable text and route
  static const String promoBannerText = 'Promo: Summit highlights — tap to learn more';
  // This can be a named route within the app or a URL handled by your navigator logic
  static const String promoBannerRoute = '/summit';
  
  /// Get the YouTube video ID from URL
  static String getVideoId() {
    return primaryLiveStreamId;
  }
  
  /// Get the complete YouTube URL
  static String getStreamUrl() {
    return primaryLiveStreamUrl;
  }
  
  /// Check if minimum watch time is met
  static bool hasMetWatchRequirement(int watchedSeconds) {
    return watchedSeconds >= requiredWatchTimeSeconds;
  }
  
  /// Get remaining watch time in seconds
  static int getRemainingWatchTime(int watchedSeconds) {
    final remaining = requiredWatchTimeSeconds - watchedSeconds;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Get watch progress percentage (0.0 to 1.0)
  static double getWatchProgress(int watchedSeconds) {
    final progress = watchedSeconds / requiredWatchTimeSeconds;
    return progress > 1.0 ? 1.0 : progress;
  }
  
  /// Format watch time display
  static String formatWatchTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  /// Get user-friendly time remaining message
  static String getTimeRemainingMessage(int watchedSeconds) {
    final remaining = getRemainingWatchTime(watchedSeconds);
    if (remaining == 0) {
      return 'Reward ready to claim!';
    }
    
    if (remaining >= 60) {
      final minutes = remaining ~/ 60;
      final seconds = remaining % 60;
      return 'Watch ${minutes}m ${seconds}s more to earn';
    } else {
      return 'Watch ${remaining}s more to earn';
    }
  }
  
  static void logWatchTime(int seconds) {
    if (kDebugMode) {
      print('🎥 Live stream watch time: ${formatWatchTime(seconds)} / ${formatWatchTime(requiredWatchTimeSeconds)}');
    }
  }
}
