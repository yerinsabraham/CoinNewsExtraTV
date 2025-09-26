import 'package:flutter/material.dart';
import 'video_detail_screen.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  
  // Only videos from YouTube links provided to the app (same as home banner carousel)
  final List<Map<String, dynamic>> _allVideos = [
    {
      'id': 'p4kmPtTU4lw',
      'title': 'Bitcoin Breaking \$100K? Market Analysis',
      'channel': 'CoinNewsExtra',
      'channelName': 'CoinNewsExtra',
      'views': '25K views',
      'uploadTime': '2 hours ago',
      'thumbnail': 'https://img.youtube.com/vi/p4kmPtTU4lw/maxresdefault.jpg',
      'duration': '12:30',
    },
    {
      'id': 'dQw4w9WgXcQ', 
      'title': 'Ethereum 2.0 Complete Guide',
      'channel': 'Crypto Education',
      'channelName': 'Crypto Education',
      'views': '18K views',
      'uploadTime': '4 hours ago',
      'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      'duration': '15:45',
    },
    {
      'id': 'L_jWHffIx5E',
      'title': 'Top 10 Altcoins for 2025', 
      'channel': 'CoinNewsExtra',
      'channelName': 'CoinNewsExtra',
      'views': '32K views',
      'uploadTime': '6 hours ago',
      'thumbnail': 'https://img.youtube.com/vi/L_jWHffIx5E/maxresdefault.jpg',
      'duration': '20:15',
    },
    {
      'id': 'fJ9rUzIMcZQ',
      'title': 'DeFi Explained: Complete Beginner Guide',
      'channel': 'DeFi Academy',
      'channelName': 'DeFi Academy',
      'views': '15K views',
      'uploadTime': '8 hours ago',
      'thumbnail': 'https://img.youtube.com/vi/fJ9rUzIMcZQ/maxresdefault.jpg',
      'duration': '18:22',
    },
    {
      'id': 'zbRSjy4CSzM',
      'title': 'NFT Market Trends & Analysis',
      'channel': 'NFT Insights',
      'channelName': 'NFT Insights',
      'views': '12K views',
      'uploadTime': '10 hours ago',
      'thumbnail': 'https://img.youtube.com/vi/zbRSjy4CSzM/maxresdefault.jpg',
      'duration': '14:08',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchResults = _allVideos; // Show all videos initially
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
          final title = video['title']?.toLowerCase() ?? '';
          final channel = video['channelName']?.toLowerCase() ?? '';
          final searchTerm = query.toLowerCase();
          
          return title.contains(searchTerm) || channel.contains(searchTerm);
        }).toList();
      }
    });
  }

  void _onVideoTap(Map<String, dynamic> video) {
    // Navigate to VideoDetailScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailScreen(
          videoId: video['id'] ?? '',
          title: video['title'] ?? 'Untitled',
          channelName: video['channelName'] ?? video['channel'] ?? 'Unknown Channel',
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
            child: _searchResults.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85, // Increased to prevent overflow
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

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return GestureDetector(
      onTap: () => _onVideoTap(video),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9, // Standard video aspect ratio
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[800],
                ),
                child: Stack(
                  children: [
                    // Thumbnail image (fallback to colored container)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF006833).withOpacity(0.3),
                            Colors.grey[800]!,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                    
                    // Duration badge
                    if (video['duration'] != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video['duration'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Video info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    video['title'] ?? 'Untitled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 3),
                  
                  // Channel name
                  Text(
                    video['channelName'] ?? 'Unknown Channel',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontFamily: 'Lato',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Views and time
                  Text(
                    '${video['views'] ?? 'N/A'} • ${video['uploadTime'] ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 9,
                      fontFamily: 'Lato',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}