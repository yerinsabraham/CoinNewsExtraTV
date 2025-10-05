import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TokenForceCollectScreen extends StatefulWidget {
  const TokenForceCollectScreen({super.key});

  @override
  State<TokenForceCollectScreen> createState() => _TokenForceCollectScreenState();
}

class _TokenForceCollectScreenState extends State<TokenForceCollectScreen> {
  bool _loading = false;
  String _status = 'Ready to force collect FCM token...';

  Future<void> _forceCollectToken() async {
    setState(() {
      _loading = true;
      _status = 'Collecting FCM token...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _status = '❌ No user logged in');
        return;
      }

      // Generate a test FCM token
      final testToken = 'fcm_test_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      
      setState(() => _status = 'Saving token to Firestore...');

      // Save directly to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': testToken,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'test_flutter',
        'tokenSource': 'force_collect_screen'
      });

      setState(() => _status = '✅ Test FCM token saved successfully!\nToken: $testToken');

    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendTestAnnouncement() async {
    setState(() {
      _loading = true;
      _status = 'Sending test announcement...';
    });

    try {
      // Create a test announcement directly in Firestore
      await FirebaseFirestore.instance
          .collection('admin_notifications')
          .add({
        'title': 'Test Push Notification',
        'message': 'This is a test push notification sent at ${DateTime.now()}',
        'priority': 'high',
        'sendPush': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'readBy': [],
      });

      setState(() => _status = '✅ Test announcement created! Check for push notification.');

    } catch (e) {
      setState(() => _status = '❌ Error creating announcement: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkTokenInFirestore() async {
    setState(() {
      _loading = true;
      _status = 'Checking Firestore...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _status = '❌ No user logged in');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final token = data['fcmToken'];
        final updatedAt = data['tokenUpdatedAt'];
        
        setState(() => _status = token != null 
            ? '✅ FCM Token found in Firestore!\nToken: $token\nUpdated: $updatedAt'
            : '❌ No FCM token found in user document');
      } else {
        setState(() => _status = '❌ User document not found');
      }

    } catch (e) {
      setState(() => _status = '❌ Error checking Firestore: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Force Token Collection'),
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
                      '🔧 Token Collection Tools',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _forceCollectToken,
                      icon: const Icon(Icons.download),
                      label: const Text('Force Collect Test Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006833),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _checkTokenInFirestore,
                      icon: const Icon(Icons.search),
                      label: const Text('Check Token in Firestore'),
                    ),
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
                      '📡 Push Notification Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _sendTestAnnouncement,
                      icon: const Icon(Icons.send),
                      label: const Text('Send Test Push Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
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
                      '📋 Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('✅')
                              ? Colors.green
                              : _status.contains('❌')
                                  ? Colors.red
                                  : Colors.white70,
                        ),
                      ),
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