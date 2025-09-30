/// YouTube Thumbnail Helper
/// Utility class for extracting YouTube video IDs and generating thumbnail URLs
class YouTubeThumbnailHelper {
  /// Extract YouTube video ID from various YouTube URL formats
  static String? extractYoutubeId(String url) {
    try {
      Uri uri = Uri.parse(url.trim());
      
      // Handle standard YouTube URLs: youtube.com/watch?v=VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
      
      // Handle short YouTube URLs: youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last.split('?').first; // Remove any query params
      }
      
      // Handle embedded URLs: youtube.com/embed/VIDEO_ID
      if (uri.host.contains('youtube.com') && 
          uri.pathSegments.length >= 2 && 
          uri.pathSegments[0] == 'embed') {
        return uri.pathSegments[1];
      }
      
      return null;
    } catch (e) {
      print('Error extracting YouTube ID from URL: $url - $e');
      return null;
    }
  }

  /// Build YouTube thumbnail URL from video ID
  /// Quality options: default, mqdefault, hqdefault, sddefault, maxresdefault
  static String buildYoutubeThumbnailUrl(String videoId, {String quality = 'hqdefault'}) {
    return "https://img.youtube.com/vi/$videoId/$quality.jpg";
  }

  /// Get thumbnail URL directly from YouTube URL
  static String? getThumbnailFromUrl(String youtubeUrl, {String quality = 'hqdefault'}) {
    String? videoId = extractYoutubeId(youtubeUrl);
    if (videoId != null) {
      return buildYoutubeThumbnailUrl(videoId, quality: quality);
    }
    return null;
  }

  /// Validate if URL is a YouTube URL
  static bool isYouTubeUrl(String url) {
    try {
      Uri uri = Uri.parse(url.trim());
      return uri.host.contains('youtube.com') || uri.host.contains('youtu.be');
    } catch (e) {
      return false;
    }
  }

  /// Get multiple thumbnail qualities for a video ID
  static Map<String, String> getAllThumbnailQualities(String videoId) {
    return {
      'default': buildYoutubeThumbnailUrl(videoId, quality: 'default'),
      'medium': buildYoutubeThumbnailUrl(videoId, quality: 'mqdefault'),
      'high': buildYoutubeThumbnailUrl(videoId, quality: 'hqdefault'),
      'standard': buildYoutubeThumbnailUrl(videoId, quality: 'sddefault'),
      'maxres': buildYoutubeThumbnailUrl(videoId, quality: 'maxresdefault'),
    };
  }
}
