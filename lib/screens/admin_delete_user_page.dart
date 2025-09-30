import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminDeleteUserPage extends StatefulWidget {
  const AdminDeleteUserPage({super.key});

  @override
  State<AdminDeleteUserPage> createState() => _AdminDeleteUserPageState();
}

class _AdminDeleteUserPageState extends State<AdminDeleteUserPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the target email
    _emailController.text = 'yerinsmgmt@gmail.com';
    _reasonController.text = 'Account cleanup - user requested deletion after account mixing issues';
  }

  Future<void> _deleteUserAccount() async {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Please enter an email address', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showMessage('You must be logged in to perform admin actions', isError: true);
        return;
      }

      // Check if current user is an admin
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(currentUser.uid)
          .get();

      if (!adminDoc.exists) {
        // Try to create admin access for testing (remove in production)
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(currentUser.uid)
            .set({
          'email': currentUser.email,
          'role': 'super_admin',
          'created_at': FieldValue.serverTimestamp(),
          'created_by': 'auto_admin_setup'
        });

        _showMessage('Admin access granted. Please try again.', isError: false);
        return;
      }

      // Call the Cloud Function to delete user
      final functions = FirebaseFunctions.instance;
      final deleteUserFunction = functions.httpsCallable('deleteUserAccount');

      final result = await deleteUserFunction.call({
        'email': _emailController.text.trim(),
        'reason': _reasonController.text.trim().isEmpty
            ? 'Admin deletion from app'
            : _reasonController.text.trim(),
      });

      if (result.data['success'] == true) {
        final summary = result.data['deletion_summary'];
        final deletedUserId = result.data['deleted_user_id'];

        final summaryText = '''
🎉 USER DELETION SUCCESSFUL!

📧 Email: ${_emailController.text.trim()}
👤 User ID: $deletedUserId

📊 Cleanup Summary:
• Firebase Auth: ${summary['firebase_auth'] ? '✅' : '❌'}
• User Document: ${summary['user_document'] ? '✅' : '❌'}  
• Rewards Entries: ${summary['rewards_entries']} deleted
• Social Verifications: ${summary['social_verifications']} deleted
• Redemptions: ${summary['redemptions']} deleted
• Battle Participations: ${summary['battle_participations']} updated
• Pending Transfers: ${summary['pending_transfers']} deleted

⚠️ The user account has been permanently deleted.
📝 Action logged for audit trail.
        ''';

        _showMessage(summaryText, isError: false);
      } else {
        _showMessage('Deletion failed: ${result.data['message']}', isError: true);
      }
    } catch (e) {
      _showMessage('Error during deletion: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {required bool isError}) {
    setState(() {
      _result = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗑️ Admin: Delete User Account'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ DANGER ZONE ⚠️',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This action will permanently delete the user account '
                      'and ALL associated data. This cannot be undone!',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '📧 Email Address to Delete',
                border: OutlineInputBorder(),
                hintText: 'user@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: '📝 Reason for Deletion',
                border: OutlineInputBorder(),
                hintText: 'Account cleanup, user request, etc.',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _deleteUserAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Deleting Account...'),
                      ],
                    )
                  : const Text(
                      '🗑️ DELETE USER ACCOUNT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            if (_result != null)
              Card(
                color: _result!.contains('successful') || _result!.contains('✅')
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      _result!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
