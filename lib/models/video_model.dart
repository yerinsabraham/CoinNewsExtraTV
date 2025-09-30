import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id; // doc id (not a list)
  final String title; // (not a list)
  final String description; // (not a list)
  final String youtubeId; // youtube video id (not a list)
  final double reward; // (not a list) - new field
  final String thumbnailUrl; // (not a list) - renamed from thumbnail
  final int durationSeconds; // (not a list)
  
  // Additional fields for UI display
  final String? url;
  final String? subtitle;
  final String? duration;
  final String? views;
  final String? uploadTime;
  final String? channelName;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeId,
    required this.reward, // (not a list) - new field
    required this.thumbnailUrl, // (not a list) - renamed from thumbnail
    required this.durationSeconds, // (not a list)
    this.url,
    this.subtitle,
    this.duration,
    this.views,
    this.uploadTime,
    this.channelName,
  });

  factory VideoModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      youtubeId: data['youtubeId'] ?? '',
      reward: (data['reward'] ?? 0.0) as double, // (not a list) - new field
      thumbnailUrl: data['thumbnailUrl'] ?? '', // (not a list) - renamed from thumbnail
      durationSeconds: (data['durationSeconds'] ?? 0) as int,
      url: data['url'],
      subtitle: data['subtitle'],
      duration: data['duration'],
      views: data['views'],
      uploadTime: data['uploadTime'],
      channelName: data['channelName'],
    );
  }

  /// Create VideoModel from Firestore data with document ID
  factory VideoModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return VideoModel(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      youtubeId: data['youtubeId'] ?? '',
      reward: (data['reward'] ?? 0.0) as double,
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      durationSeconds: _parseDurationToSeconds(data['duration'] ?? ''),
      url: data['url'],
      subtitle: data['subtitle'],
      duration: data['duration'],
      views: data['views'],
      uploadTime: data['uploadTime'],
      channelName: data['channelName'],
    );
  }

  /// Create VideoModel from JSON (for static data)
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? json['title'] ?? '',
      youtubeId: json['id'] ?? '', // Use id as youtubeId for static data
      reward: (json['reward'] ?? 0.0) as double,
      thumbnailUrl: json['thumbnail'] ?? '',
      durationSeconds: _parseDurationToSeconds(json['duration'] ?? ''),
      url: json['url'],
      subtitle: json['subtitle'],
      duration: json['duration'],
      views: json['views'],
      uploadTime: json['uploadTime'],
      channelName: json['channelName'],
    );
  }

  /// Get YouTube thumbnail URL for this video
  String get youtubeThumbnailUrl {
    if (thumbnailUrl.isNotEmpty) {
      return thumbnailUrl;
    }
    return 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
  }

  /// Get high resolution YouTube thumbnail URL
  String get youtubeHighResThumbnailUrl {
    return 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg';
  }

  /// Get YouTube watch URL
  String get youtubeWatchUrl {
    if (url != null && url!.isNotEmpty) {
      return url!;
    }
    return 'https://www.youtube.com/watch?v=$youtubeId';
  }

  /// Helper method to parse duration string to seconds
  static int _parseDurationToSeconds(String duration) {
    if (duration.isEmpty) return 0;
    
    final parts = duration.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return (minutes * 60) + seconds;
    }
    return 0;
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
}
