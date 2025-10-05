import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProvider extends ChangeNotifier {
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _isLoading = false;
  String? _adminId;

  bool get isAdmin => _isAdmin;
  bool get isSuperAdmin => _isSuperAdmin;
  bool get isLoading => _isLoading;
  String? get adminId => _adminId;

  // Super admin emails (hardcoded as requested)
  static const List<String> superAdminEmails = [
    'yerinssaibs@gmail.com',
    'elitepr@coinnewsextra.com',
  ];

  Future<void> initializeAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _resetAdminStatus();
      return;
    }

    await checkAdminStatus(user.email ?? '');
  }

  Future<void> checkAdminStatus(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user is super admin
      if (superAdminEmails.contains(email.toLowerCase())) {
        _isAdmin = true;
        _isSuperAdmin = true;
        _adminId = FirebaseAuth.instance.currentUser?.uid;
        
        // Ensure super admin document exists in Firestore
        await _ensureSuperAdminDoc(email);
      } else {
        // Check if user is regular admin
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();

        if (adminDoc.exists) {
          final data = adminDoc.data()!;
          _isAdmin = true;
          _isSuperAdmin = data['isSuperAdmin'] ?? false;
          _adminId = adminDoc.id;
        } else {
          _resetAdminStatus();
        }
      }
    } catch (e) {
      print('Error checking admin status: $e');
      _resetAdminStatus();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _ensureSuperAdminDoc(String email) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final adminRef = FirebaseFirestore.instance.collection('admins').doc(uid);
      await adminRef.set({
        'email': email,
        'isSuperAdmin': true,
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'permissions': [
          'user_management',
          'content_management',
          'system_administration',
          'support_management'
        ],
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error ensuring super admin doc: $e');
    }
  }

  Future<void> addAdmin(String email, {bool isSuperAdmin = false}) async {
    if (!_isSuperAdmin) {
      throw Exception('Only super admins can add other admins');
    }

    try {
      // This would need to be implemented with a cloud function
      // since we can't directly create users from the client
      await FirebaseFirestore.instance.collection('admin_requests').add({
        'email': email,
        'isSuperAdmin': isSuperAdmin,
        'requestedBy': _adminId,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('Error adding admin: $e');
      rethrow;
    }
  }

  Future<void> removeAdmin(String adminId) async {
    if (!_isSuperAdmin) {
      throw Exception('Only super admins can remove other admins');
    }

    try {
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .delete();
    } catch (e) {
      print('Error removing admin: $e');
      rethrow;
    }
  }

  void _resetAdminStatus() {
    _isAdmin = false;
    _isSuperAdmin = false;
    _adminId = null;
  }

  void logout() {
    _resetAdminStatus();
    notifyListeners();
  }
}
