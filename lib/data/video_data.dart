import '../models/video_model.dart';

class VideoData {
  static final List<VideoModel> _mockVideos = [
    VideoModel(
      id: 'p4kmPtTU4lw',
      youtubeId: 'p4kmPtTU4lw',
      title: 'Crypto Market Analysis & Trends',
      channelName: 'CoinNews Extra',
      description: 'Deep dive into crypto market trends and analysis',
      publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      viewCount: 15000,
      reward: 5.0,
      subtitle: 'CoinNews Extra',
      views: '15K views',
      uploadTime: '2 hours ago',
      url: 'https://youtu.be/p4kmPtTU4lw?si=EAZq9QCUWDCwPOat',
      durationSeconds: 765,
    ),
    VideoModel(
      id: 'Xhq15-cr8mI',
      youtubeId: 'Xhq15-cr8mI',
      title: 'Bitcoin Price Prediction 2024',
      channelName: 'CoinNews Extra',
      description: 'Complete analysis of Bitcoin price predictions for 2024',
      publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      viewCount: 23000,
      reward: 5.0,
      subtitle: 'CoinNews Extra',
      views: '23K views',
      uploadTime: '5 hours ago',
      url: 'https://youtu.be/Xhq15-cr8mI?si=aRujNNaB1je-MQaC',
      durationSeconds: 510,
    ),
    VideoModel(
      id: 'hfDtTPkPy7E',
      youtubeId: 'hfDtTPkPy7E',
      title: 'DeFi Protocol Deep Dive',
      channelName: 'CoinNews Extra',
      description: 'Understanding decentralized finance protocols',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      viewCount: 8500,
      reward: 5.0,
      subtitle: 'CoinNews Extra',
      views: '8.5K views',
      uploadTime: '1 day ago',
      url: 'https://youtu.be/hfDtTPkPy7E?si=3PRfRt7hrWKNKbRN',
      durationSeconds: 920,
    ),
    VideoModel(
      id: 'w6Rbpe_Sb3M',
      youtubeId: 'w6Rbpe_Sb3M',
      title: 'NFT Market Update & Analysis',
      channelName: 'CoinNews Extra',
      description: 'Latest trends in the NFT marketplace',
      publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
      viewCount: 12000,
      reward: 5.0,
      subtitle: 'CoinNews Extra',
      views: '12K views',
      uploadTime: '3 hours ago',
      url: 'https://youtu.be/w6Rbpe_Sb3M?si=QKxmVnbfUv8_p2Df',
      durationSeconds: 615,
    ),
    VideoModel(
      id: 'EXqQwDbuW6M',
      youtubeId: 'EXqQwDbuW6M',
      title: 'Blockchain Technology Explained',
      channelName: 'CoinNews Extra',
      description: 'Complete guide to blockchain technology fundamentals',
      publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
      viewCount: 31000,
      reward: 5.0,
      subtitle: 'CoinNews Extra',
      views: '31K views',
      uploadTime: '6 hours ago',
      url: 'https://youtu.be/EXqQwDbuW6M?si=kkIYhwl_qMoW4Uwg',
      durationSeconds: 1125,
    ),
  ];

  static List<VideoModel> getAllVideos() {
    return List.from(_mockVideos);
  }

  static List<VideoModel> getFeaturedVideos() {
    return _mockVideos.take(3).toList();
  }

  static List<VideoModel> getCarouselVideos() {
    return _mockVideos.take(5).toList();
  }

  static List<VideoModel> getRecentVideos() {
    return _mockVideos.where((video) {
      if (video.publishedAt == null) return false;
      final daysSincePublished = DateTime.now().difference(video.publishedAt!).inDays;
      return daysSincePublished <= 7;
    }).toList();
  }

  static List<VideoModel> getPopularVideos() {
    return List.from(_mockVideos)
      ..sort((a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0));
  }

  static VideoModel? getVideoById(String youtubeId) {
    try {
      return _mockVideos.firstWhere((video) => video.youtubeId == youtubeId);
    } catch (e) {
      return null;
    }
  }

  static List<VideoModel> searchVideos(String query) {
    if (query.isEmpty) return getAllVideos();
    
    final lowercaseQuery = query.toLowerCase();
    return _mockVideos.where((video) {
      final titleMatch = video.title.toLowerCase().contains(lowercaseQuery);
      final channelMatch = (video.channelName ?? '').toLowerCase().contains(lowercaseQuery);
      final descriptionMatch = (video.description ?? '').toLowerCase().contains(lowercaseQuery);
      
      return titleMatch || channelMatch || descriptionMatch;
    }).toList();
  }
}
