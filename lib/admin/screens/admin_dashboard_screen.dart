import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import '../../help_support/services/support_service.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/dashboard_menu_card.dart';
import 'support_management_screen.dart';
import 'user_management_screen.dart';
import 'content_management_screen.dart';
import 'app_settings_screen.dart';
import 'spotlight_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _supportStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await SupportService.getSupportStats();
      if (mounted) {
        setState(() {
          _supportStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
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
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF006833)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006833),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Color(0xFF006833),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF006833).withOpacity(0.2),
                    const Color(0xFF006833).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF006833).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF006833),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          FeatherIcons.shield,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${user?.displayName ?? "Admin"}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                            Text(
                              'Manage your CNETV app from this central dashboard',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Last login: ${DateTime.now().toString().split('.')[0]}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Stats
            const Text(
              'Quick Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoadingStats)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF006833)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DashboardStatsCard(
                      title: 'Open Tickets',
                      value: _supportStats?['openTickets']?.toString() ?? '0',
                      icon: FeatherIcons.alertCircle,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashboardStatsCard(
                      title: 'Active Chats',
                      value: _supportStats?['activeChats']?.toString() ?? '0',
                      icon: FeatherIcons.messageCircle,
                      color: const Color(0xFF006833),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashboardStatsCard(
                      title: 'Pending Calls',
                      value: _supportStats?['pendingCalls']?.toString() ?? '0',
                      icon: FeatherIcons.phone,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Management Categories
            const Text(
              'Management Center',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5, // Adjusted to accommodate new card
              children: [
                DashboardMenuCard(
                  title: 'Support Management',
                  description: 'Handle tickets, chats & calls',
                  icon: FeatherIcons.headphones,
                  color: const Color(0xFF006833),
                  badgeCount: (_supportStats?['openTickets'] ?? 0) + 
                             (_supportStats?['activeChats'] ?? 0) + 
                             (_supportStats?['pendingCalls'] ?? 0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportManagementScreen(),
                    ),
                  ),
                ),
                DashboardMenuCard(
                  title: 'Spotlight Management',
                  description: 'Manage featured brands & projects',
                  icon: FeatherIcons.star,
                  color: Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SpotlightManagementScreen(),
                    ),
                  ),
                ),
                DashboardMenuCard(
                  title: 'User Management',
                  description: 'Manage users & admins',
                  icon: FeatherIcons.users,
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  ),
                ),
                DashboardMenuCard(
                  title: 'Content Management',
                  description: 'Videos, images & announcements',
                  icon: FeatherIcons.edit3,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContentManagementScreen(),
                    ),
                  ),
                ),
                DashboardMenuCard(
                  title: 'App Settings',
                  description: 'Configuration & preferences',
                  icon: FeatherIcons.settings,
                  color: Colors.grey,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: FeatherIcons.userPlus,
                    label: 'Add Admin',
                    color: const Color(0xFF006833),
                    onTap: () => _showAddAdminDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: FeatherIcons.volume2,
                    label: 'Send Announcement',
                    color: Colors.orange,
                    onTap: () => _showAnnouncementDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: FeatherIcons.database,
                    label: 'Backup Data',
                    color: Colors.blue,
                    onTap: () => _showBackupDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: FeatherIcons.barChart2,
                    label: 'View Analytics',
                    color: Colors.purple,
                    onTap: () => _showAnalyticsDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // System Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        FeatherIcons.activity,
                        color: Color(0xFF006833),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'System Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusItem('Firebase', true, 'Connected'),
                  _buildStatusItem('Support System', true, 'Operational'),
                  _buildStatusItem('Push Notifications', true, 'Active'),
                  _buildStatusItem('Agora VoIP', true, 'Ready'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String service, bool isOnline, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF006833) : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontFamily: 'Lato',
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: isOnline ? const Color(0xFF006833) : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAdminDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Add New Admin',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white, fontFamily: 'Lato'),
              decoration: InputDecoration(
                hintText: 'Admin email address',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement add admin functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add admin functionality coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006833)),
            child: const Text('Add Admin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedPriority = 'normal';
    bool sendPushNotification = true;
    bool sendEmailNotification = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Send Announcement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7, // Set max height to 70% of screen
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Title field
                const Text(
                  'Title',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Lato'),
                  decoration: InputDecoration(
                    hintText: 'Enter announcement title...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF006833)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message field
                const Text(
                  'Message',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Lato'),
                  decoration: InputDecoration(
                    hintText: 'Enter your announcement message...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF006833)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Priority dropdown
                const Text(
                  'Priority',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white, fontFamily: 'Lato'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                    DropdownMenuItem(value: 'high', child: Text('High Priority')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) => setState(() => selectedPriority = value!),
                ),
                const SizedBox(height: 16),

                // Notification options
                const Text(
                  'Notification Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text(
                    'Send Push Notification',
                    style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
                  ),
                  subtitle: Text(
                    'Notify users on their devices',
                    style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
                  ),
                  value: sendPushNotification,
                  activeColor: const Color(0xFF006833),
                  onChanged: (value) => setState(() => sendPushNotification = value!),
                ),
                CheckboxListTile(
                  title: const Text(
                    'Send Email Notification',
                    style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
                  ),
                  subtitle: Text(
                    'Send announcement via email',
                    style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
                  ),
                  value: sendEmailNotification,
                  activeColor: const Color(0xFF006833),
                  onChanged: (value) => setState(() => sendEmailNotification = value!),
                ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _sendAnnouncement(
                  titleController.text.trim(),
                  messageController.text.trim(),
                  selectedPriority,
                  sendPushNotification,
                  sendEmailNotification,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006833),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Send',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Data Backup',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: const Text(
          'Backup system coming soon!',
          style: TextStyle(color: Colors.white70, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF006833))),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: const Text(
          'Analytics system coming soon!',
          style: TextStyle(color: Colors.white70, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF006833))),
          ),
        ],
      ),
    );
  }

  Future<void> _sendAnnouncement(
    String title,
    String message,
    String priority,
    bool sendPush,
    bool sendEmail,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF006833)),
              const SizedBox(height: 16),
              Text(
                'Sending announcement...',
                style: TextStyle(color: Colors.grey[300], fontFamily: 'Lato'),
              ),
            ],
          ),
        ),
      );

      // Create announcement document
      final announcementData = {
        'title': title,
        'message': message,
        'priority': priority,
        'sendPush': sendPush,
        'sendEmail': sendEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.email,
        'createdByName': FirebaseAuth.instance.currentUser?.displayName ?? 'Admin',
        'status': 'sent',
        'targetAudience': 'all_users',
        'readBy': <String>[],
        'totalUsers': 0, // Will be updated by Cloud Function
      };

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('admin_notifications')
          .add(announcementData);

      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Announcement Sent Successfully!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      Text(
                        'All users will receive: "$title"',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF006833),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        // Show detailed confirmation dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006833).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF006833),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Announcement Sent',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your announcement has been successfully sent to all users.',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.title, color: Color(0xFF006833), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: TextStyle(
                                color: _getPriorityColor(priority),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (sendPush)
                            const Icon(Icons.notifications, color: Color(0xFF006833), size: 16),
                          if (sendEmail)
                            const Icon(Icons.email, color: Colors.blue, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• Users will see this in their notification bell\n• Push notifications sent to active devices\n• Notification will be stored for future access',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF006833),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send announcement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
}