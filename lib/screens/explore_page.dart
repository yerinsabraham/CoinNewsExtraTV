import 'package:flutter/material.dart';
import 'video_detail_screen.dart';
import '../services/youtube_thumbnail_service.dart';
import '../widgets/youtube_thumbnail_widget.dart';
import '../data/video_data.dart';
import '../models/video_model.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeThumbnailService _thumbnailService = YouTubeThumbnailService();
  List<VideoModel> _searchResults = [];
  List<VideoModel> _allVideos = [];
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      setState(() => _isLoading = true);
      
      // Load videos from Firebase database
      final videos = await VideoData.getExploreVideosFromDatabase();
      
      setState(() {
        _allVideos = videos;
        _searchResults = videos; // Show all videos initially
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading videos: $e');
      setState(() {
        _allVideos = VideoData.getExploreVideos(); // Fallback to static
        _searchResults = _allVideos;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      
      if (query.isEmpty) {
        _searchResults = _allVideos;
      } else {
        _searchResults = _allVideos.where((video) {
          final title = video.title.toLowerCase();
          final channel = (video.channelName ?? '').toLowerCase();
          final searchTerm = query.toLowerCase();
          
          return title.contains(searchTerm) || channel.contains(searchTerm);
        }).toList();
      }
    });
  }

  void _onVideoTap(VideoModel video) {
    // Navigate to VideoDetailScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailScreen(
          videoId: video.youtubeId,
          title: video.title,
          channelName: video.channelName ?? 'CoinNews Extra',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Explore',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
      ),
      body: Column(
        children: [
          // Search section
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF006833).withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lato',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search videos...',
                        hintStyle: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Lato',
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF006833),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.tune,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Show filter options
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter options coming soon!')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Results info
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'} found',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const Spacer(),
                  if (_searchController.text.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: Color(0xFF006833),
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Video grid
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _searchResults.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75, // Reduced to provide more height
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final video = _searchResults[index];
                          return _buildVideoCard(video);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF006833),
          ),
          SizedBox(height: 16),
          Text(
            'Loading videos...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No videos found',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(VideoModel video) {
    return YouTubeGridItem(
      youtubeUrl: video.youtubeWatchUrl,
      title: video.title,
      channelName: video.channelName ?? 'CoinNews Extra',
      views: video.views,
      timeAgo: video.uploadTime,
      onTap: () => _onVideoTap(video),
    );
  }
}