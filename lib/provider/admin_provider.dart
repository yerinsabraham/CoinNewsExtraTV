import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_role.dart';
import '../services/admin_auth_service.dart';

class AdminProvider extends ChangeNotifier {
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _isLoading = false;
  String? _adminId;
  AdminRole? _adminRole;
  AdminUser? _adminUser;
  
  final AdminAuthService _authService = AdminAuthService();

  bool get isAdmin => _isAdmin;
  bool get isSuperAdmin => _isSuperAdmin;
  bool get isLoading => _isLoading;
  String? get adminId => _adminId;
  AdminRole? get adminRole => _adminRole;
  AdminUser? get adminUser => _adminUser;
  
  // Check if user is Finance Admin
  bool get isFinanceAdmin => _adminRole == AdminRole.financeAdmin;
  
  // Check if user is Updates Admin
  bool get isUpdatesAdmin => _adminRole == AdminRole.updatesAdmin;

  // Super admin emails (legacy - kept for backwards compatibility)
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
      // Check if user is one of the new role-based admins
      final role = AdminPermissions.getRoleFromEmail(email);
      
      if (role != null) {
        _isAdmin = true;
        _isSuperAdmin = role == AdminRole.superAdmin;
        _adminRole = role;
        _adminId = FirebaseAuth.instance.currentUser?.uid;
        
        // Fetch full admin user data
        if (_adminId != null) {
          _adminUser = await _authService.getAdminUser(_adminId!);
        }
      } 
      // Backwards compatibility: Check legacy super admins
      else if (superAdminEmails.contains(email.toLowerCase())) {
        _isAdmin = true;
        _isSuperAdmin = true;
        _adminRole = AdminRole.superAdmin;
        _adminId = FirebaseAuth.instance.currentUser?.uid;
        
        // Ensure super admin document exists in Firestore
        await _ensureSuperAdminDoc(email);
      } else {
        // Check if user is regular admin in Firestore
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();

        if (adminDoc.exists) {
          final data = adminDoc.data()!;
          _isAdmin = true;
          _isSuperAdmin = data['isSuperAdmin'] ?? false;
          _adminRole = _isSuperAdmin ? AdminRole.superAdmin : AdminRole.updatesAdmin;
          _adminId = adminDoc.id;
          _adminUser = AdminUser.fromFirestore(data, adminDoc.id);
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
  
  // Check specific permission
  bool hasPermission(String permission) {
    if (_adminRole == null) return false;
    final permissions = AdminPermissions.getPermissionsForRole(_adminRole!);
    return permissions.contains(permission);
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
    _adminRole = null;
    _adminUser = null;
  }

  void logout() {
    _resetAdminStatus();
    notifyListeners();
  }
  
  // Log admin action
  Future<void> logAction(String action, Map<String, dynamic> details) async {
    await _authService.logAdminAction(action: action, details: details);
  }
}
