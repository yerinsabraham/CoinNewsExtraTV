import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_role.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in as admin with role-based access
  Future<AdminUser?> signInAdmin(String email, String password) async {
    try {
      // Check if email is authorized
      if (!AdminPermissions.isAuthorizedAdmin(email)) {
        throw Exception('Unauthorized: This email is not registered as an admin account');
      }

      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      // Get role from email
      final role = AdminPermissions.getRoleFromEmail(email);
      if (role == null) {
        throw Exception('Unable to determine admin role');
      }

      // Create or update admin document in Firestore
      await _ensureAdminDocument(user.uid, email, role);

      // Fetch and return admin user
      return await getAdminUser(user.uid);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Admin account not found. Please contact system administrator.');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-email':
          throw Exception('Invalid email format');
        case 'user-disabled':
          throw Exception('This admin account has been disabled');
        default:
          throw Exception('Authentication failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign in error: $e');
    }
  }

  // Create or update admin document in Firestore
  Future<void> _ensureAdminDocument(String uid, String email, AdminRole role) async {
    final adminRef = _firestore.collection('admins').doc(uid);
    
    await adminRef.set({
      'email': email,
      'role': role.toStringValue(),
      'lastLogin': FieldValue.serverTimestamp(),
      'isActive': true,
      'permissions': AdminPermissions.getPermissionsForRole(role),
    }, SetOptions(merge: true));

    // If this is the first time, also set createdAt
    final doc = await adminRef.get();
    if (doc.data()?['createdAt'] == null) {
      await adminRef.update({
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get admin user from Firestore
  Future<AdminUser?> getAdminUser(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      
      if (!doc.exists) {
        return null;
      }

      return AdminUser.fromFirestore(doc.data()!, uid);
    } catch (e) {
      print('Error fetching admin user: $e');
      return null;
    }
  }

  // Get current admin user if signed in
  Future<AdminUser?> getCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return await getAdminUser(user.uid);
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final email = user.email;
    if (email == null) return false;

    return AdminPermissions.isAuthorizedAdmin(email);
  }

  // Get current admin role
  Future<AdminRole?> getCurrentAdminRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final email = user.email;
    if (email == null) return null;

    return AdminPermissions.getRoleFromEmail(email);
  }

  // Check specific permission
  Future<bool> hasPermission(String permission) async {
    final role = await getCurrentAdminRole();
    if (role == null) return false;

    final permissions = AdminPermissions.getPermissionsForRole(role);
    return permissions.contains(permission);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Log admin action
  Future<void> logAdminAction({
    required String action,
    required Map<String, dynamic> details,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final admin = await getCurrentAdmin();
    if (admin == null) return;

    await _firestore.collection('admin_actions').add({
      'adminUid': user.uid,
      'adminEmail': user.email,
      'adminRole': admin.role.toStringValue(),
      'action': action,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get admin action history
  Stream<QuerySnapshot> getAdminActions({int limit = 50}) {
    return _firestore
        .collection('admin_actions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Update admin status (Super Admin only)
  Future<void> updateAdminStatus(String uid, bool isActive) async {
    final currentRole = await getCurrentAdminRole();
    if (currentRole != AdminRole.superAdmin) {
      throw Exception('Only Super Admin can modify admin accounts');
    }

    await _firestore.collection('admins').doc(uid).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await logAdminAction(
      action: isActive ? 'enable_admin' : 'disable_admin',
      details: {'targetAdminUid': uid},
    );
  }

  // Get all admins (Super Admin only)
  Future<List<AdminUser>> getAllAdmins() async {
    final currentRole = await getCurrentAdminRole();
    if (currentRole != AdminRole.superAdmin) {
      throw Exception('Only Super Admin can view all admin accounts');
    }

    final snapshot = await _firestore.collection('admins').get();
    
    return snapshot.docs.map((doc) {
      return AdminUser.fromFirestore(doc.data(), doc.id);
    }).toList();
  }
}
