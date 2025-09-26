import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sample notifications data
  List<NotificationItem> _allNotifications = [
    NotificationItem(
      id: '1',
      title: 'New Video Available',
      description: 'Bitcoin Breaking \$100K? Market Analysis is now live',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: NotificationType.video,
      actionData: {'videoId': 'p4kmPtTU4lw'},
    ),
    NotificationItem(
      id: '2',
      title: 'Reward Earned',
      description: 'You earned 5 CNE tokens for watching a video',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: false,
      type: NotificationType.reward,
      actionData: {'amount': 5},
    ),
    NotificationItem(
      id: '3',
      title: 'Market Alert',
      description: 'Bitcoin price has increased by 5% in the last hour',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      isRead: true,
      type: NotificationType.market,
      actionData: {'symbol': 'BTC', 'change': '+5%'},
    ),
    NotificationItem(
      id: '4',
      title: 'Daily Check-in Reminder',
      description: 'Don\'t forget to claim your daily 20 CNE bonus!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
      type: NotificationType.reminder,
      actionData: {},
    ),
    NotificationItem(
      id: '5',
      title: 'Community Update',
      description: 'New message in the crypto trading chat group',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.community,
      actionData: {'chatId': 'crypto-trading'},
    ),
    NotificationItem(
      id: '6',
      title: 'App Update Available',
      description: 'Version 1.1.0 is available with new features',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: NotificationType.update,
      actionData: {},
    ),
  ];

  List<String> _categories = ['All', 'Videos', 'Rewards', 'Market', 'Updates'];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedCategoryIndex == 0) return _allNotifications;
    
    final categoryMap = {
      1: NotificationType.video,
      2: NotificationType.reward,
      3: NotificationType.market,
      4: NotificationType.update,
    };
    
    final filterType = categoryMap[_selectedCategoryIndex];
    return _allNotifications.where((n) => n.type == filterType).toList();
  }

  int get _unreadCount {
    return _allNotifications.where((n) => !n.isRead).length;
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _allNotifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _allNotifications[index].isRead = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _allNotifications) {
        notification.isRead = true;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _allNotifications.removeWhere((n) => n.id == id);
    });
  }

  void _onNotificationTap(NotificationItem notification) {
    _markAsRead(notification.id);
    
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.video:
        // Navigate to video player
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening video: ${notification.actionData['videoId']}')),
        );
        break;
      case NotificationType.reward:
        // Navigate to earning page
        Navigator.pushNamed(context, '/earning');
        break;
      case NotificationType.market:
        // Navigate to market page
        Navigator.pushNamed(context, '/market-cap');
        break;
      case NotificationType.community:
        // Navigate to chat
        Navigator.pushNamed(context, '/chat');
        break;
      case NotificationType.reminder:
        // Navigate to earning page
        Navigator.pushNamed(context, '/earning');
        break;
      case NotificationType.update:
        // Show update info
        _showUpdateDialog();
        break;
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'App Update',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Version 1.1.0 includes new search features, notifications, and bug fixes.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redirecting to app store...')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
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
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFF006833),
                  fontFamily: 'Lato',
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isSelected = _selectedCategoryIndex == index;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF006833) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Notifications list
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return _buildNotificationItem(notification);
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
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new notifications in this category',
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

  Widget _buildNotificationItem(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.red,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.grey[900] : Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead 
                  ? Colors.transparent 
                  : const Color(0xFF006833).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // Icon based on type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                        if (!notification.isRead)
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
                      notification.description,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Lato',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontFamily: 'Lato',
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

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.video:
        return Icons.play_circle_outline;
      case NotificationType.reward:
        return Icons.monetization_on_outlined;
      case NotificationType.market:
        return Icons.trending_up;
      case NotificationType.community:
        return Icons.chat_bubble_outline;
      case NotificationType.reminder:
        return Icons.notifications_outlined;
      case NotificationType.update:
        return Icons.system_update;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.video:
        return Colors.blue;
      case NotificationType.reward:
        return const Color(0xFF006833);
      case NotificationType.market:
        return Colors.orange;
      case NotificationType.community:
        return Colors.purple;
      case NotificationType.reminder:
        return Colors.amber;
      case NotificationType.update:
        return Colors.cyan;
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;
  final Map<String, dynamic> actionData;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isRead,
    required this.type,
    required this.actionData,
  });
}

enum NotificationType {
  video,
  reward,
  market,
  community,
  reminder,
  update,
}