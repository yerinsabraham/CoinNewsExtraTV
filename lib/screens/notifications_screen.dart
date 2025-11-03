import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get all unread notifications
      final unreadNotifications = await FirebaseFirestore.instance
          .collection('admin_notifications')
          .where('readBy', whereNotIn: [user.uid])
          .get();

      // Mark each as read
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadNotifications.docs) {
        final data = doc.data();
        final readBy = List<String>.from(data['readBy'] ?? []);
        if (!readBy.contains(user.uid)) {
          readBy.add(user.uid);
          batch.update(doc.reference, {'readBy': readBy});
        }
      }
      
      if (unreadNotifications.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Error marking notifications as read: $e');
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.checkCircle, color: Colors.white),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin_notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006833)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.alertCircle, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.bell, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll receive announcements and\nupdates from the CoinNewsExtra team here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildNotificationCard(data, doc.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data, String docId) {
    final user = FirebaseAuth.instance.currentUser;
    final readBy = List<String>.from(data['readBy'] ?? []);
    final isRead = user != null && readBy.contains(user.uid);
    
    final createdAt = data['createdAt'] as Timestamp?;
    final timeAgo = createdAt != null 
        ? timeago.format(createdAt.toDate())
        : 'Unknown time';

    final priority = data['priority'] as String? ?? 'normal';
    final title = data['title'] as String? ?? 'Notification';
    final message = data['message'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[900] : Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey[800]! : const Color(0xFF006833).withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with priority and time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        color: _getPriorityColor(priority),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        priority.toUpperCase(),
                        style: TextStyle(
                          color: _getPriorityColor(priority),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF006833),
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: TextStyle(
                color: isRead ? Colors.grey[300] : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: TextStyle(
                color: isRead ? Colors.grey[400] : Colors.grey[300],
                fontSize: 14,
                fontFamily: 'Lato',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Footer (delivery indicators only)
            if (data['sendPush'] == true || data['sendEmail'] == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (data['sendPush'] == true)
                    Icon(
                      FeatherIcons.smartphone,
                      color: Colors.grey[500],
                      size: 14,
                    ),
                  if (data['sendEmail'] == true) ...[
                    const SizedBox(width: 8),
                    Icon(
                      FeatherIcons.mail,
                      color: Colors.grey[500],
                      size: 14,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'normal':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return FeatherIcons.info;
      case 'normal':
        return FeatherIcons.bell;
      case 'high':
        return FeatherIcons.alertTriangle;
      case 'urgent':
        return FeatherIcons.alertCircle;
      default:
        return FeatherIcons.bell;
    }
  }
}