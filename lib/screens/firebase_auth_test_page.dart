// Simple test to check Firebase Auth status
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthTestPage extends StatefulWidget {
  const FirebaseAuthTestPage({super.key});

  @override
  State<FirebaseAuthTestPage> createState() => _FirebaseAuthTestPageState();
}

class _FirebaseAuthTestPageState extends State<FirebaseAuthTestPage> {
  String _status = 'Checking...';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check current user
      final user = FirebaseAuth.instance.currentUser;
      
      setState(() {
        _currentUser = user;
      });

      if (user == null) {
        setState(() {
          _status = '❌ No user signed in';
        });
        return;
      }

      // Check if user document exists
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String status = '✅ User authenticated:\n';
      status += 'UID: ${user.uid}\n';
      status += 'Email: ${user.email}\n';
      status += 'Display Name: ${user.displayName}\n';
      status += 'Email Verified: ${user.emailVerified}\n';
      status += 'User Doc Exists: ${userDoc.exists}\n';

      // Try to read social verifications
      try {
        final socialVerifications = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('social_verifications')
            .limit(1)
            .get();
        
        status += 'Social Verifications Access: ✅ Success\n';
        status += 'Social Docs Count: ${socialVerifications.docs.length}\n';
      } catch (e) {
        status += 'Social Verifications Access: ❌ Error\n';
        status += 'Error: $e\n';
      }

      // Try to write a test document
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('social_verifications')
            .doc('test')
            .set({
          'test': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        status += 'Write Test: ✅ Success\n';
        
        // Clean up test document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('social_verifications')
            .doc('test')
            .delete();
        
        status += 'Cleanup: ✅ Success\n';
      } catch (e) {
        status += 'Write Test: ❌ Error\n';
        status += 'Write Error: $e\n';
      }

      setState(() {
        _status = status;
      });

    } catch (e) {
      setState(() {
        _status = '❌ Error checking auth: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Test'),
        backgroundColor: const Color(0xFF006833),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Authentication Status:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkAuthStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006833),
                    ),
                    child: const Text('Refresh Status'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_currentUser != null) {
                        await FirebaseAuth.instance.signOut();
                        _checkAuthStatus();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
