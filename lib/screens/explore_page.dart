import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'video_detail_page.dart';
import '../models/video_model.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  List<ExploreVideo> _searchResults = [];
  List<ExploreVideo> _allVideos = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _selectedCategory = 'All';
  
  final List<String> _categories = [
    'All',
    'Crypto News',
    'Market Analysis',
    'Interviews',
    'Education',
    'Technology',
    'Trading',
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() {
    setState(() => _isLoading = true);
    
    // Simulate loading and populate with demo videos
    Future.delayed(const Duration(milliseconds: 800), () {
      final videos = _generateDemoVideos();
      setState(() {
        _allVideos = videos;
        _searchResults = videos;
        _isLoading = false;
      });
    });
  }

  List<ExploreVideo> _generateDemoVideos() {
    return [
      ExploreVideo(
        id: '1',
        title: 'Bitcoin Market Analysis: What\'s Next?',
        channelName: 'CoinNews Extra',
        thumbnailUrl: 'assets/images/video-thumbnail-1.jpg',
        duration: '12:45',
        views: '125K views',
        timeAgo: '2 hours ago',
        category: 'Market Analysis',
      ),
      ExploreVideo(
        id: '2',
        title: 'Ethereum 2.0 Complete Guide',
        channelName: 'Crypto Education Hub',
        thumbnailUrl: 'assets/images/video-thumbnail-2.jpg',
        duration: '18:30',
        views: '89K views',
        timeAgo: '5 hours ago',
        category: 'Education',
      ),
      ExploreVideo(
        id: '3',
        title: 'Exclusive Interview with Vitalik Buterin',
        channelName: 'Blockchain Interviews',
        thumbnailUrl: 'assets/images/video-thumbnail-3.jpg',
        duration: '45:20',
        views: '234K views',
        timeAgo: '1 day ago',
        category: 'Interviews',
      ),
      ExploreVideo(
        id: '4',
        title: 'Top 10 DeFi Protocols to Watch',
        channelName: 'DeFi Insights',
        thumbnailUrl: 'assets/images/video-thumbnail-4.jpg',
        duration: '15:15',
        views: '67K views',
        timeAgo: '2 days ago',
        category: 'Technology',
      ),
      ExploreVideo(
        id: '5',
        title: 'Breaking: New Crypto Regulations',
        channelName: 'Crypto News Today',
        thumbnailUrl: 'assets/images/video-thumbnail-5.jpg',
        duration: '8:45',
        views: '156K views',
        timeAgo: '3 hours ago',
        category: 'Crypto News',
      ),
      ExploreVideo(
        id: '6',
        title: 'Day Trading Strategies for Beginners',
        channelName: 'Trading Academy',
        thumbnailUrl: 'assets/images/video-thumbnail-6.jpg',
        duration: '22:10',
        views: '92K views',
        timeAgo: '6 hours ago',
        category: 'Trading',
      ),
      ExploreVideo(
        id: '7',
        title: 'NFT Market Crash or Opportunity?',
        channelName: 'NFT Analysis',
        thumbnailUrl: 'assets/images/video-thumbnail-7.jpg',
        duration: '14:30',
        views: '78K views',
        timeAgo: '12 hours ago',
        category: 'Market Analysis',
      ),
      ExploreVideo(
        id: '8',
        title: 'Blockchain Technology Explained',
        channelName: 'Tech Simplified',
        thumbnailUrl: 'assets/images/video-thumbnail-8.jpg',
        duration: '16:55',
        views: '145K views',
        timeAgo: '1 day ago',
        category: 'Education',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _filterResults();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _filterResults();
    });
  }

  void _filterResults() {
    List<ExploreVideo> filtered = _allVideos;
    
    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((video) => video.category == _selectedCategory).toList();
    }
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((video) {
        return video.title.toLowerCase().contains(query) ||
               video.channelName.toLowerCase().contains(query) ||
               video.category.toLowerCase().contains(query);
      }).toList();
    }
    
    _searchResults = filtered;
  }

  void _onVideoTap(ExploreVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailPage(
          video: VideoModel(
            id: video.id,
            youtubeId: video.id,
            title: video.title,
            description: 'Explore crypto content and earn rewards!',
            thumbnailUrl: video.thumbnailUrl,
            channelName: video.channelName,
            views: video.views,
            reward: 5.0, // Default reward
          ),
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
          'Explore Videos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.grid, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Grid view options coming soon!'),
                  backgroundColor: Color(0xFF006833),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search section
          _buildSearchSection(),
          
          // Category filter
          _buildCategoryFilter(),
          
          // Results info
          _buildResultsInfo(),
          
          // Video grid
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _searchResults.isEmpty
                    ? _buildEmptyState()
                    : _buildVideoGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
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
                  hintText: 'Search videos, channels...',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Lato',
                  ),
                  prefixIcon: Icon(
                    FeatherIcons.search,
                    color: Colors.white54,
                    size: 20,
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
                FeatherIcons.sliders,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                _showFilterDialog();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'Lato',
                ),
              ),
              selected: isSelected,
              onSelected: (selected) => _onCategoryChanged(category),
              backgroundColor: Colors.grey[900],
              selectedColor: const Color(0xFF006833),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF006833) : Colors.grey[700]!,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            '${_searchResults.length} video${_searchResults.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Lato',
            ),
          ),
          if (_selectedCategory != 'All') ...[
            Text(
              ' in $_selectedCategory',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontFamily: 'Lato',
              ),
            ),
          ],
          const Spacer(),
          if (_isSearching || _selectedCategory != 'All')
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = 'All';
                  _isSearching = false;
                  _searchResults = _allVideos;
                });
              },
              icon: const Icon(
                FeatherIcons.x,
                color: Color(0xFF006833),
                size: 16,
              ),
              label: const Text(
                'Clear',
                style: TextStyle(
                  color: Color(0xFF006833),
                  fontFamily: 'Lato',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final video = _searchResults[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(ExploreVideo video) {
    return GestureDetector(
      onTap: () => _onVideoTap(video),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF006833).withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        FeatherIcons.play,
                        color: Colors.white.withOpacity(0.8),
                        size: 32,
                      ),
                    ),
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
                          video.duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Channel name
                    Text(
                      video.channelName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontFamily: 'Lato',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Views and time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${video.views} • ${video.timeAgo}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              fontFamily: 'Lato',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            FeatherIcons.search,
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
            _isSearching 
                ? 'Try different keywords or categories'
                : 'No videos available in this category',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadVideos,
            icon: const Icon(FeatherIcons.refreshCw),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006833),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Filter Options',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Lato',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(FeatherIcons.clock, color: Color(0xFF006833)),
                title: const Text(
                  'Sort by Upload Date',
                  style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sort feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(FeatherIcons.eye, color: Color(0xFF006833)),
                title: const Text(
                  'Sort by View Count',
                  style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sort feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(FeatherIcons.filter, color: Color(0xFF006833)),
                title: const Text(
                  'Duration Filter',
                  style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Duration filter coming soon!')),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF006833),
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ExploreVideo {
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String duration;
  final String views;
  final String timeAgo;
  final String category;

  ExploreVideo({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.duration,
    required this.views,
    required this.timeAgo,
    required this.category,
  });
}