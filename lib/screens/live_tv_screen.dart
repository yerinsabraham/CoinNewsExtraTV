import 'package:flutter/material.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  // Sample live channels data
  final List<Map<String, dynamic>> _liveChannels = [
    {
      'name': 'Crypto News 24/7',
      'description': 'Latest cryptocurrency news and market updates',
      'thumbnail': 'https://img.youtube.com/vi/M7lc1UVf-VE/maxresdefault.jpg',
      'viewers': '2.3K',
      'isLive': true,
      'category': 'News',
    },
    {
      'name': 'Bitcoin Analysis Live',
      'description': 'Real-time Bitcoin price analysis and trading signals',
      'thumbnail': 'https://img.youtube.com/vi/3jDhvKczYdQ/maxresdefault.jpg',
      'viewers': '1.8K',
      'isLive': true,
      'category': 'Analysis',
    },
    {
      'name': 'DeFi Education Stream',
      'description': 'Learn about DeFi protocols and yield farming',
      'thumbnail': 'https://img.youtube.com/vi/oHg5SJYRHA0/maxresdefault.jpg',
      'viewers': '945',
      'isLive': true,
      'category': 'Education',
    },
    {
      'name': 'NFT Marketplace Tour',
      'description': 'Exploring the latest NFT collections and trends',
      'thumbnail': 'https://img.youtube.com/vi/RDxaVw3X74s/maxresdefault.jpg',
      'viewers': '567',
      'isLive': false,
      'category': 'NFTs',
      'nextStream': 'Starting in 2 hours',
    },
  ];

  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'News', 'Analysis', 'Education', 'NFTs'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.live_tv, color: Color(0xFF006833)),
            const SizedBox(width: 8),
            const Text(
              'Live TV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[800],
                    selectedColor: const Color(0xFF006833),
                    checkmarkColor: Colors.black,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF006833) : Colors.grey[700]!,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Featured Live Stream (if any)
          if (_liveChannels.where((channel) => channel['isLive']).isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF006833).withOpacity(0.2),
                    const Color(0xFF006833).withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: const Color(0xFF006833)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Featured Stream',
                        style: TextStyle(
                          color: Color(0xFF006833),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _liveChannels.first['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _liveChannels.first['description'],
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_liveChannels.first['viewers']} viewers watching',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Live Channels List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _getFilteredChannels().length,
              itemBuilder: (context, index) {
                final channel = _getFilteredChannels()[index];
                return _buildChannelCard(channel);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Go Live feature coming soon!')),
          );
        },
        backgroundColor: const Color(0xFF006833),
        child: const Icon(Icons.videocam, color: Colors.white),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredChannels() {
    if (_selectedCategory == 'All') {
      return _liveChannels;
    }
    return _liveChannels.where((channel) => channel['category'] == _selectedCategory).toList();
  }

  Widget _buildChannelCard(Map<String, dynamic> channel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (channel['isLive']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Joining ${channel['name']}...')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${channel['name']} is offline. ${channel['nextStream']}')),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: channel['isLive'] ? const Color(0xFF006833).withOpacity(0.3) : Colors.grey[800]!,
            ),
          ),
          child: Row(
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 120,
                      height: 68,
                      child: Image.network(
                        channel['thumbnail'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Icon(
                              channel['isLive'] ? Icons.live_tv : Icons.tv_off,
                              color: Colors.white,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Live indicator
                  if (channel['isLive'])
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Category badge
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        channel['category'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Channel info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            channel['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (channel['isLive'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF006833),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      channel['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      channel['isLive'] 
                          ? '${channel['viewers']} viewers'
                          : channel['nextStream'],
                      style: TextStyle(
                        color: channel['isLive'] ? const Color(0xFF006833) : Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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
}
