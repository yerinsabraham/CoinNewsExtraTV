import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String youtubeId;
  final String title;
  final String? channelName;
  final String? description;
  final String? thumbnailUrl;
  final DateTime? publishedAt;
  final int? viewCount;
  final int? duration;
  final double reward;
  final int durationSeconds;
  
  // Additional fields for UI display
  final String? url;
  final String? subtitle;
  final String? views;
  final String? uploadTime;

  VideoModel({
    required this.id,
    required this.youtubeId,
    required this.title,
    this.channelName,
    this.description,
    this.thumbnailUrl,
    this.publishedAt,
    this.viewCount,
    this.duration,
    this.reward = 0.0,
    this.durationSeconds = 0,
    this.url,
    this.subtitle,
    this.views,
    this.uploadTime,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? json['youtubeId'] ?? '',
      youtubeId: json['youtubeId'] ?? '',
      title: json['title'] ?? '',
      channelName: json['channelName'],
      description: json['description'],
      thumbnailUrl: json['thumbnailUrl'],
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt']) 
          : null,
      viewCount: json['viewCount'],
      duration: json['duration'],
      reward: (json['reward'] ?? 0.0) as double,
      durationSeconds: parseDurationToSeconds(json['duration'] ?? ''),
      url: json['url'],
      subtitle: json['subtitle'],
      views: json['views'],
      uploadTime: json['uploadTime'],
    );
  }

  /// Create VideoModel from Firestore document
  factory VideoModel.fromDoc(doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel.fromFirestore(data, doc.id);
  }

  /// Create VideoModel from Firestore data
  factory VideoModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return VideoModel(
      id: docId,
      youtubeId: data['youtubeId'] ?? '',
      title: data['title'] ?? '',
      channelName: data['channelName'],
      description: data['description'],
      thumbnailUrl: data['thumbnailUrl'],
      publishedAt: data['publishedAt'] != null 
          ? (data['publishedAt'] as Timestamp).toDate()
          : null,
      viewCount: data['viewCount'],
      duration: data['duration'],
      reward: (data['reward'] ?? 0.0) as double,
      durationSeconds: parseDurationToSeconds(data['duration']?.toString() ?? ''),
      url: data['url'],
      subtitle: data['subtitle'],
      views: data['views']?.toString(),
      uploadTime: data['uploadTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'youtubeId': youtubeId,
      'title': title,
      'channelName': channelName,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'publishedAt': publishedAt?.toIso8601String(),
      'viewCount': viewCount,
      'duration': duration,
      'reward': reward,
      'durationSeconds': durationSeconds,
      'url': url,
      'subtitle': subtitle,
      'views': views,
      'uploadTime': uploadTime,
    };
  }

  /// Get YouTube thumbnail URL for this video
  String get youtubeThumbnailUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return thumbnailUrl!;
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

  /// Extract video ID from various YouTube URL formats
  static String? extractVideoId(String inputUrl) {
    if (inputUrl.isEmpty) return null;

    // Handle youtu.be format
    if (inputUrl.contains('youtu.be/')) {
      final match = RegExp(r'youtu\.be\/([a-zA-Z0-9_-]+)').firstMatch(inputUrl);
      return match?.group(1);
    }

    // Handle youtube.com/watch format
    if (inputUrl.contains('youtube.com/watch')) {
      final match = RegExp(r'[?&]v=([a-zA-Z0-9_-]+)').firstMatch(inputUrl);
      return match?.group(1);
    }

    // Handle youtube.com/embed format
    if (inputUrl.contains('youtube.com/embed/')) {
      final match = RegExp(r'embed\/([a-zA-Z0-9_-]+)').firstMatch(inputUrl);
      return match?.group(1);
    }

    // If it's already just an ID
    if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(inputUrl) && inputUrl.length == 11) {
      return inputUrl;
    }

    return null;
  }

  /// Helper method to parse duration string to seconds
  static int parseDurationToSeconds(String duration) {
    if (duration.isEmpty) return 0;
    
    final parts = duration.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return (minutes * 60) + seconds;
    }
    return 0;
  }
}
