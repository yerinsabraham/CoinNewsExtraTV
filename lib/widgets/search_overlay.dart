import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

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
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> _filteredVideos = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _filteredVideos = widget.videos;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterVideos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVideos = widget.videos;
      } else {
        _filteredVideos = widget.videos.where((video) {
          final title = video['title']?.toString().toLowerCase() ?? '';
          final channel = video['channel']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          
          return title.contains(searchQuery) || channel.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _closeSearch() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: SafeArea(
          child: Column(
            children: [
              // Search header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Lato',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search videos and channels...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: 'Lato',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey[600]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF006833),
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            FeatherIcons.search,
                            color: Color(0xFF006833),
                          ),
                          filled: true,
                          fillColor: Colors.grey[900],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: _filterVideos,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _closeSearch,
                      icon: const Icon(
                        FeatherIcons.x,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search results
              Expanded(
                child: _filteredVideos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FeatherIcons.search,
                              color: Colors.grey[600],
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _controller.text.isEmpty
                                  ? 'Start typing to search...'
                                  : 'No results found',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredVideos.length,
                        itemBuilder: (context, index) {
                          final video = _filteredVideos[index];
                          return _buildVideoItem(video);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF006833).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            FeatherIcons.play,
            color: Color(0xFF006833),
          ),
        ),
        title: Text(
          video['title'] ?? 'Unknown Title',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Lato',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          video['channel'] ?? 'Unknown Channel',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontFamily: 'Lato',
          ),
        ),
        trailing: const Icon(
          FeatherIcons.chevronRight,
          color: Colors.grey,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playing: '),
              backgroundColor: const Color(0xFF006833),
            ),
          );
          _closeSearch();
        },
      ),
    );
  }
}
