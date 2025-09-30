import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// YouTube Thumbnail Service with fallback hierarchy and caching
/// Implements product acceptance requirement #1 for thumbnail management
class YouTubeThumbnailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheKeyPrefix = 'yt_thumbnail_';
  static const Duration _cacheExpiry = Duration(days: 7);
  
  /// YouTube thumbnail quality hierarchy - try in order until 200 response
  static const List<String> _thumbnailQualities = [
    'maxresdefault.jpg',  // 1280x720
    'hqdefault.jpg',      // 480x360  
    'mqdefault.jpg',      // 320x180
  ];

  /// Extract YouTube video ID from various URL formats
  static String? extractVideoId(String url) {
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)'),
      RegExp(r'youtube\.com\/v\/([^&\n?#]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Get thumbnail URL with fallback hierarchy and caching
  static Future<String> getThumbnailUrl(String videoId) async {
    try {
      // Check cache first
      final cachedUrl = await _getCachedThumbnailUrl(videoId);
      if (cachedUrl != null) {
        return cachedUrl;
      }

      // Try each quality level until we get a 200 response
      for (final quality in _thumbnailQualities) {
        final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/$quality';
        
        try {
          final response = await http.head(Uri.parse(thumbnailUrl)).timeout(
            const Duration(seconds: 5),
          );
          
          if (response.statusCode == 200) {
            // Cache successful URL
            await _cacheThumbnailUrl(videoId, thumbnailUrl);
            await _updateFirestoreVideoRecord(videoId, thumbnailUrl);
            return thumbnailUrl;
          }
        } catch (e) {
          // Continue to next quality if this one fails
          debugPrint('Failed to fetch $quality for $videoId: $e');
        }
      }

      // If all YouTube thumbnails fail, return fallback
      final fallbackUrl = _getFallbackThumbnailUrl();
      await _cacheThumbnailUrl(videoId, fallbackUrl);
      return fallbackUrl;
      
    } catch (e) {
      debugPrint('Error in getThumbnailUrl for $videoId: $e');
      return _getFallbackThumbnailUrl();
    }
  }

  /// Get cached thumbnail URL if still valid
  static Future<String?> _getCachedThumbnailUrl(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$videoId';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        final cachedAt = DateTime.parse(data['cachedAt']);
        final url = data['url'] as String;
        
        // Check if cache is still valid
        if (DateTime.now().difference(cachedAt) < _cacheExpiry) {
          return url;
        } else {
          // Remove expired cache
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      debugPrint('Error reading thumbnail cache for $videoId: $e');
    }
    return null;
  }

  /// Cache thumbnail URL with timestamp
  static Future<void> _cacheThumbnailUrl(String videoId, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$videoId';
      final cacheData = {
        'url': url,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error caching thumbnail for $videoId: $e');
    }
  }

  /// Update Firestore video record with thumbnail info
  static Future<void> _updateFirestoreVideoRecord(String videoId, String thumbnailUrl) async {
    try {
      await _firestore.collection('videos').doc(videoId).set({
        'youtubeId': videoId,
        'thumbnailUrl': thumbnailUrl,
        'lastCheckedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating Firestore for video $videoId: $e');
    }
  }

  /// Get fallback thumbnail URL for failed/private videos
  static String _getFallbackThumbnailUrl() {
    // Return app asset fallback image path
    return 'assets/images/video_placeholder.png';
  }

  /// Widget builder for thumbnail with loading states
  static Widget buildThumbnailWidget({
    required String videoId,
    required Widget child,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? semanticLabel,
  }) {
    return FutureBuilder<String>(
      future: getThumbnailUrl(videoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Icon(
              Icons.video_library,
              color: Colors.white,
              size: 64,
            ),
          );
        }

        final thumbnailUrl = snapshot.data!;
        
        // Check if it's the fallback asset
        if (thumbnailUrl.startsWith('assets/')) {
          return Container(
            width: width,
            height: height,
            child: Stack(
              children: [
                Image.asset(
                  thumbnailUrl,
                  width: width,
                  height: height,
                  fit: fit,
                  semanticLabel: semanticLabel,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.video_library,
                        color: Colors.white,
                        size: 64,
                      ),
                    );
                  },
                ),
                child,
              ],
            ),
          );
        }

        // Network image with error handling
        return Container(
          width: width,
          height: height,
          child: Stack(
            children: [
              Image.network(
                thumbnailUrl,
                width: width,
                height: height,
                fit: fit,
                semanticLabel: semanticLabel,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[800],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading thumbnail $thumbnailUrl: $error');
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.video_library,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
              child,
            ],
          ),
        );
      },
    );
  }

  /// Clear thumbnail cache (for testing/debugging)
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing thumbnail cache: $e');
    }
  }

  /// Get cached thumbnail count (for debugging)
  static Future<int> getCachedThumbnailCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix)).length;
    } catch (e) {
      debugPrint('Error getting cache count: $e');
      return 0;
    }
  }
}
