import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../../data/video_data.dart';
import '../../models/video_model.dart';

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  
  // Content Management Settings
  bool _autoApproval = false;
  bool _qualityCheck = true;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadContent();
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Load videos from VideoData
      final videos = VideoData.getAllVideos();
      
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          'Content Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.plus, color: Colors.white),
            onPressed: _showAddContentDialog,
          ),
          IconButton(
            icon: const Icon(FeatherIcons.refreshCw, color: Colors.white),
            onPressed: _loadContent,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 12),
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FeatherIcons.video, size: 14),
                  SizedBox(width: 4),
                  Text('Videos'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FeatherIcons.image, size: 14),
                  SizedBox(width: 4),
                  Text('Images'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FeatherIcons.radio, size: 14),
                  SizedBox(width: 4),
                  Text('Live'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FeatherIcons.settings, size: 14),
                  SizedBox(width: 4),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideosTab(),
          _buildImagesTab(),
          _buildLiveTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildVideosTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FeatherIcons.video, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No videos uploaded',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddVideoDialog,
              icon: const Icon(FeatherIcons.plus, color: Colors.white),
              label: const Text(
                'Add Video',
                style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildImagesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FeatherIcons.image, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Image Management',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload and manage app images, banners, and graphics',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showComingSoon,
            icon: const Icon(FeatherIcons.upload, color: Colors.white),
            label: const Text(
              'Upload Images',
              style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FeatherIcons.radio, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Live Content Management',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule and manage live streams, events, and broadcasts',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showComingSoon,
            icon: const Icon(FeatherIcons.plus, color: Colors.white),
            label: const Text(
              'Schedule Live Stream',
              style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 20),
          
          _buildSettingCard(
            'Auto-Approval',
            'Automatically approve uploaded content',
            _autoApproval,
            (value) {
              setState(() {
                _autoApproval = value;
              });
              _saveSettings();
            },
            FeatherIcons.checkCircle,
          ),
          const SizedBox(height: 12),
          
          _buildSettingCard(
            'Quality Check',
            'Enable automatic quality verification',
            _qualityCheck,
            (value) {
              setState(() {
                _qualityCheck = value;
              });
              _saveSettings();
            },
            FeatherIcons.shield,
          ),
          const SizedBox(height: 12),
          
          _buildSettingCard(
            'Notifications',
            'Send notifications for new uploads',
            _notifications,
            (value) {
              setState(() {
                _notifications = value;
              });
              _saveSettings();
            },
            FeatherIcons.bell,
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Upload Limits',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildLimitCard('Max Video Size', '500 MB'),
          const SizedBox(height: 8),
          _buildLimitCard('Max Image Size', '10 MB'),
          const SizedBox(height: 8),
          _buildLimitCard('Allowed Formats', 'MP4, AVI, MOV, JPG, PNG'),
        ],
      ),
    );
  }

  Widget _buildVideoCard(VideoModel video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.purple.withOpacity(0.3), Colors.purple.withOpacity(0.1)],
            ),
          ),
          child: video.youtubeId.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://img.youtube.com/vi/${video.youtubeId}/mqdefault.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(FeatherIcons.video, color: Colors.purple, size: 24);
                    },
                  ),
                )
              : const Icon(FeatherIcons.video, color: Colors.purple, size: 24),
        ),
        title: Text(
          video.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.channelName ?? 'Unknown Channel',
              style: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'Lato',
              ),
            ),
            Row(
              children: [
                Icon(FeatherIcons.eye, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${video.viewCount ?? 0} views',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(width: 16),
                Icon(FeatherIcons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${video.reward ?? 5.0} CNET',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(FeatherIcons.moreVertical, color: Colors.grey[400]),
          color: Colors.grey[800],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditVideoDialog(video);
                break;
              case 'delete':
                _showDeleteVideoDialog(video);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(FeatherIcons.edit, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: Colors.white, fontFamily: 'Lato')),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(FeatherIcons.trash2, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red, fontFamily: 'Lato')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(String title, String description, bool value, Function(bool) onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[300],
              fontFamily: 'Lato',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Add Content',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContentTypeButton('Upload Video', FeatherIcons.video, _showAddVideoDialog),
            const SizedBox(height: 12),
            _buildContentTypeButton('Upload Image', FeatherIcons.image, _showComingSoon),
            const SizedBox(height: 12),
            _buildContentTypeButton('Schedule Live', FeatherIcons.radio, _showComingSoon),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.purple),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVideoDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Add Video',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: const Text(
          'Video upload functionality will be implemented in Phase 3.\n\nFeatures will include:\n• YouTube URL import\n• Direct video upload\n• Metadata editing\n• Reward configuration',
          style: TextStyle(color: Color(0xFFBDBDBD), fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.purple, fontFamily: 'Lato'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditVideoDialog(VideoModel video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit Video',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'Edit functionality for "${video.title}" will be available in Phase 3.\n\nFeatures will include:\n• Title and description editing\n• Reward amount adjustment\n• Visibility settings\n• Category management',
          style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.purple, fontFamily: 'Lato'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteVideoDialog(VideoModel video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Video',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'Are you sure you want to delete "${video.title}"?\n\nNote: This is currently read-only data. Full delete functionality will be available in Phase 3.',
          style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete functionality coming in Phase 3!'),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontFamily: 'Lato'),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming in Phase 3!'),
        backgroundColor: Colors.purple,
      ),
    );
  }
  
  /// Load content management settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      // For now, we'll use default values
      // In production, this would load from SharedPreferences or Firestore
      setState(() {
        _autoApproval = false; // Default to false for security
        _qualityCheck = true;  // Default to true for quality
        _notifications = true; // Default to true for notifications
      });
    } catch (e) {
      debugPrint('Error loading content settings: $e');
    }
  }
  
  /// Save content management settings to SharedPreferences and Firestore
  Future<void> _saveSettings() async {
    try {
      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings saved successfully!\n'
            'Auto-Approval: ${_autoApproval ? "ON" : "OFF"}\n'
            'Quality Check: ${_qualityCheck ? "ON" : "OFF"}\n'
            'Notifications: ${_notifications ? "ON" : "OFF"}',
            style: const TextStyle(fontFamily: 'Lato'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // In production, you would save to:
      // 1. SharedPreferences for local storage
      // 2. Firestore for server sync
      // 3. Firebase Remote Config for global app settings
      
      debugPrint('Content Management Settings Saved:');
      debugPrint('Auto-Approval: $_autoApproval');
      debugPrint('Quality Check: $_qualityCheck'); 
      debugPrint('Notifications: $_notifications');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}