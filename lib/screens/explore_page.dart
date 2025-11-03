import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'video_detail_page.dart';
import '../models/video_model.dart';
import '../data/video_data.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  List<VideoModel> _searchResults = [];
  List<VideoModel> _allVideos = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _selectedCategory = 'All';
  
  final List<String> _categories = [
    'All',
    'Recent',
    'Popular',
    'Trending',
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() {
    setState(() => _isLoading = true);
    
    // Load real video data from video_data.dart
    Future.delayed(const Duration(milliseconds: 500), () {
      final videos = VideoData.getAllVideos();
      setState(() {
        _allVideos = videos;
        _searchResults = videos;
        _isLoading = false;
      });
    });
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
    List<VideoModel> filtered = _allVideos;
    
    // Apply category filter
    if (_selectedCategory == 'Recent') {
      filtered = VideoData.getRecentVideos();
    } else if (_selectedCategory == 'Popular') {
      filtered = VideoData.getPopularVideos();
    } else if (_selectedCategory == 'Trending') {
      filtered = VideoData.getFeaturedVideos();
    }
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((video) {
        return video.title.toLowerCase().contains(query) ||
               (video.channelName ?? '').toLowerCase().contains(query) ||
               (video.description ?? '').toLowerCase().contains(query);
      }).toList();
    }
    
    _searchResults = filtered;
  }

  void _onVideoTap(VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailPage(video: video),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 30),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85, // Increased to fix 8.7px overflow
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final video = _searchResults[index];
          return _buildVideoCard(video);
        },
      ),
    );
  }

  Widget _buildVideoCard(VideoModel video) {
    final duration = video.durationSeconds != null 
        ? '${(video.durationSeconds! ~/ 60)}:${(video.durationSeconds! % 60).toString().padLeft(2, '0')}'
        : '0:00';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onVideoTap(video),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with YouTube preview
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF006833).withOpacity(0.3),
                        const Color(0xFF00A651).withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // YouTube thumbnail (we'll show the YouTube ID as placeholder since we have real YouTube IDs)
                      if (video.youtubeId.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            'https://img.youtube.com/vi/${video.youtubeId}/maxresdefault.jpg',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to medium quality thumbnail
                              return Image.network(
                                'https://img.youtube.com/vi/${video.youtubeId}/mqdefault.jpg',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Final fallback to gradient with play icon
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF006833).withOpacity(0.5),
                                          const Color(0xFF00A651).withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_outline,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      
                      // Play icon overlay
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      
                      // Duration badge
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            duration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      ),
                      
                      // Reward badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF006833), Color(0xFF00A651)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${video.reward ?? 5.0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Video info section
              Container(
                height: 68, // Reduced height to fix overflow
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Expanded(
                      flex: 2,
                      child: Text(
                        video.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Channel name and views in a single row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            video.channelName ?? 'CoinNews Extra',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontFamily: 'Lato',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.visibility,
                          color: Colors.grey[500],
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          video.views ?? '0',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 9,
                            fontFamily: 'Lato',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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