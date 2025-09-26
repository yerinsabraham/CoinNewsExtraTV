import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/video_detail_screen.dart';

class SearchOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final VoidCallback onClose;

  const SearchOverlay({
    super.key,
    required this.videos,
    required this.onClose,
  });

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [
    'Bitcoin analysis',
    'Ethereum news',
    'DeFi explained',
    'Crypto trading',
  ];
  
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    
    // Auto-focus search input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = widget.videos.where((video) {
      final title = video['title']?.toLowerCase() ?? '';
      final channel = video['channelName']?.toLowerCase() ?? video['channel']?.toLowerCase() ?? '';
      final searchTerm = query.toLowerCase();
      
      return title.contains(searchTerm) || channel.contains(searchTerm);
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  void _selectSearch(String searchTerm) {
    _searchController.text = searchTerm;
    _performSearch(searchTerm);
    
    // Add to recent searches if not already present
    if (!_recentSearches.contains(searchTerm)) {
      setState(() {
        _recentSearches.insert(0, searchTerm);
        if (_recentSearches.length > 6) {
          _recentSearches = _recentSearches.take(6).toList();
        }
      });
    }
  }

  void _closeSearch() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Background overlay
              GestureDetector(
                onTap: _closeSearch,
                child: Container(
                  color: Colors.black.withOpacity(_fadeAnimation.value),
                ),
              ),
              
              // Search container
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * 100),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF006833).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Lato',
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search videos, news...',
                                  hintStyle: TextStyle(
                                    color: Colors.white54,
                                    fontFamily: 'Lato',
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                                child: const Icon(
                                  Icons.clear,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _closeSearch,
                              child: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Search content
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]!.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _searchController.text.isEmpty
                              ? _buildRecentSearches()
                              : _buildSearchResults(),
                        ),
                      ),
                      
                      const SizedBox(height: 100), // Space for bottom navigation
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Recent Searches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return ListTile(
                leading: const Icon(
                  Icons.history,
                  color: Colors.white54,
                  size: 20,
                ),
                title: Text(
                  search,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lato',
                  ),
                ),
                onTap: () => _selectSearch(search),
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      _recentSearches.removeAt(index);
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white54,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final video = _searchResults[index];
              return ListTile(
                leading: Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  video['title'] ?? 'Untitled',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Lato',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  video['channelName'] ?? video['channel'] ?? 'Unknown Channel',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
                onTap: () {
                  // Close search and navigate based on content type
                  _closeSearch();
                  
                  // Check if it's a video (has videoId) or news content
                  if (video['id'] != null && video['id'].toString().isNotEmpty) {
                    // It's a video - navigate to VideoDetailScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoDetailScreen(
                          videoId: video['id'],
                          title: video['title'] ?? 'Untitled',
                          channelName: video['channelName'] ?? video['channel'] ?? 'Unknown Channel',
                        ),
                      ),
                    );
                  } else {
                    // It's news content - navigate to news page
                    Navigator.pushNamed(context, '/news');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}