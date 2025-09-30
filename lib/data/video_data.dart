import '../models/video_model.dart';
import '../services/video_service.dart';

class VideoData {
  static const List<Map<String, dynamic>> _videoData = [
    {
      "id": "p4kmPtTU4lw",
      "url": "https://youtu.be/p4kmPtTU4lw?si=EAZq9QCUWDCwPOat",
      "title": "Crypto Market Analysis & Trends",
      "subtitle": "CoinNews Extra",
      "thumbnail": "",
      "duration": "12:45",
      "views": "15K views",
      "uploadTime": "2 hours ago",
      "channelName": "CoinNews Extra"
    },
    {
      "id": "Xhq15-cr8mI", 
      "url": "https://youtu.be/Xhq15-cr8mI?si=aRujNNaB1je-MQaC",
      "title": "Bitcoin Price Prediction 2024",
      "subtitle": "CoinNews Extra",
      "thumbnail": "",
      "duration": "8:30",
      "views": "23K views", 
      "uploadTime": "5 hours ago",
      "channelName": "CoinNews Extra"
    },
    {
      "id": "hfDtTPkPy7E",
      "url": "https://youtu.be/hfDtTPkPy7E?si=3PRfRt7hrWKNKbRN", 
      "title": "DeFi Protocol Deep Dive",
      "subtitle": "CoinNews Extra",
      "thumbnail": "",
      "duration": "15:20",
      "views": "8.5K views",
      "uploadTime": "1 day ago", 
      "channelName": "CoinNews Extra"
    },
    {
      "id": "w6Rbpe_Sb3M",
      "url": "https://youtu.be/w6Rbpe_Sb3M?si=QKxmVnbfUv8_p2Df",
      "title": "NFT Market Update & Analysis", 
      "subtitle": "CoinNews Extra",
      "thumbnail": "",
      "duration": "10:15",
      "views": "12K views",
      "uploadTime": "3 hours ago",
      "channelName": "CoinNews Extra"
    },
    {
      "id": "EXqQwDbuW6M",
      "url": "https://youtu.be/EXqQwDbuW6M?si=kkIYhwl_qMoW4Uwg",
      "title": "Blockchain Technology Explained",
      "subtitle": "CoinNews Extra", 
      "thumbnail": "",
      "duration": "18:45",
      "views": "31K views",
      "uploadTime": "6 hours ago",
      "channelName": "CoinNews Extra"
    }
  ];

  /// Get all videos as VideoModel objects
  static List<VideoModel> getAllVideos() {
    return _videoData.map((data) => VideoModel.fromJson(data)).toList();
  }

  /// Get a specific video by ID
  static VideoModel? getVideoById(String id) {
    try {
      final data = _videoData.firstWhere((video) => video['id'] == id);
      return VideoModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Get videos for home carousel (all 5 videos)
  static List<VideoModel> getCarouselVideos() {
    return getAllVideos();
  }

  /// Get videos for explore page grid (all 5 videos)
  static List<VideoModel> getExploreVideos() {
    return getAllVideos();
  }

  /// Get featured video for banners (first video)
  static VideoModel getFeaturedVideo() {
    return getAllVideos().first;
  }

  /// Get random video for ads/promotions
  static VideoModel getRandomVideo() {
    final videos = getAllVideos();
    videos.shuffle();
    return videos.first;
  }

  /// Get videos from Firebase with static fallback
  static Future<List<VideoModel>> getVideosFromDatabase() async {
    try {
      return await VideoService.getVideos();
    } catch (e) {
      print('❌ Error fetching from database, using static data: $e');
      return getAllVideos();
    }
  }

  /// Get videos for home carousel from database
  static Future<List<VideoModel>> getCarouselVideosFromDatabase() async {
    return await getVideosFromDatabase();
  }

  /// Get videos for explore page from database
  static Future<List<VideoModel>> getExploreVideosFromDatabase() async {
    return await getVideosFromDatabase();
  }

  /// Get featured video from database
  static Future<VideoModel> getFeaturedVideoFromDatabase() async {
    final videos = await getVideosFromDatabase();
    return videos.isNotEmpty ? videos.first : getFeaturedVideo();
  }

  /// Get random video from database
  static Future<VideoModel> getRandomVideoFromDatabase() async {
    final videos = await getVideosFromDatabase();
    if (videos.isNotEmpty) {
      videos.shuffle();
      return videos.first;
    }
    return getRandomVideo();
  }
}
