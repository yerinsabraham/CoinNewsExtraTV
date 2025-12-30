import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String? _fcmToken;
  bool _loading = false;
  String _status = 'Ready to test...';

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    setState(() => _loading = true);
    try {
      final token = NotificationService().fcmToken;
      setState(() {
        _fcmToken = token;
        _status = token != null ? 'FCM Token loaded successfully!' : 'FCM Token not found';
      });
    } catch (e) {
      setState(() => _status = 'Error loading FCM token: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _loading = true);
    try {
      await NotificationService().sendTestNotification();
      setState(() => _status = 'Test notification sent! Check your device.');
    } catch (e) {
      setState(() => _status = 'Error sending test notification: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkUserDocument() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _status = 'No user logged in');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final storedToken = data['fcmToken'] as String?;
        setState(() {
          _status = storedToken != null 
              ? 'FCM token stored in Firestore ✅\nToken: ${storedToken.substring(0, 20)}...'
              : 'FCM token NOT stored in Firestore ❌';
        });
      } else {
        setState(() => _status = 'User document not found');
      }
    } catch (e) {
      setState(() => _status = 'Error checking user document: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM Token copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notification Test'),
        backgroundColor: const Color(0xFF006833),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📱 FCM Token Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _status.contains('✅') 
                            ? Colors.green 
                            : _status.contains('❌') 
                                ? Colors.red 
                                : Colors.white70,
                      ),
                    ),
                    if (_fcmToken != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'FCM Token:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _fcmToken!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _copyToken,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Token'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Test Functions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _loadFCMToken,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh FCM Token'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _checkUserDocument,
                      icon: const Icon(Icons.cloud),
                      label: const Text('Check Firestore Storage'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _sendTestNotification,
                      icon: const Icon(Icons.notification_add),
                      label: const Text('Send Local Test Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006833),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Testing Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Login as super admin (yerinssaibs@gmail.com)\n'
                      '2. Go to Admin Dashboard\n'
                      '3. Click "Send Announcements"\n'
                      '4. Create announcement with "Send Push" enabled\n'
                      '5. Check your device for push notification',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}