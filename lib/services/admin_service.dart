import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_models.dart';

class AdminService {
  static const String superAdminEmail = 'yerinssaibs@gmail.com';
  static const String adminsCollection = 'admins';
  static const String contentCollection = 'admin_content';
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Check if current user is super admin
  static bool isSuperAdmin() {
    final user = _auth.currentUser;
    return user?.email?.toLowerCase() == superAdminEmail.toLowerCase();
  }
  
  // Check if current user is admin (including super admin)
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Super admin always has access
    if (isSuperAdmin()) return true;
    
    try {
      final adminDoc = await _firestore
          .collection(adminsCollection)
          .doc(user.uid)
          .get();
      
      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        return data['isActive'] == true;
      }
      
      // Also check by email in case UID is different
      final emailQuery = await _firestore
          .collection(adminsCollection)
          .where('email', isEqualTo: user.email?.toLowerCase())
          .where('isActive', isEqualTo: true)
          .get();
      
      return emailQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
  
  // Add new admin (only super admin can do this)
  static Future<bool> addAdmin(String email, {String? role}) async {
    if (!isSuperAdmin()) {
      throw Exception('Only super admin can add new admins');
    }
    
    try {
      final adminData = AdminUser(
        id: '', // Will be set by Firestore
        email: email.toLowerCase().trim(),
        role: role ?? 'admin',
        isActive: true,
        addedBy: _auth.currentUser!.email!,
        addedAt: DateTime.now(),
        lastLoginAt: null,
      );
      
      // Add to admins collection
      await _firestore.collection(adminsCollection).add(adminData.toJson());
      
      return true;
    } catch (e) {
      print('Error adding admin: $e');
      return false;
    }
  }
  
  // Remove admin (only super admin can do this)
  static Future<bool> removeAdmin(String adminId) async {
    if (!isSuperAdmin()) {
      throw Exception('Only super admin can remove admins');
    }
    
    try {
      await _firestore
          .collection(adminsCollection)
          .doc(adminId)
          .update({'isActive': false});
      
      return true;
    } catch (e) {
      print('Error removing admin: $e');
      return false;
    }
  }
  
  // Get all admins (only super admin can see this)
  static Future<List<AdminUser>> getAllAdmins() async {
    if (!isSuperAdmin()) {
      throw Exception('Only super admin can view all admins');
    }
    
    try {
      final querySnapshot = await _firestore
          .collection(adminsCollection)
          .orderBy('addedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => AdminUser.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting admins: $e');
      return [];
    }
  }
  
  // Update admin last login
  static Future<void> updateLastLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Check if user is admin
      final adminQuery = await _firestore
          .collection(adminsCollection)
          .where('email', isEqualTo: user.email?.toLowerCase())
          .where('isActive', isEqualTo: true)
          .get();
      
      if (adminQuery.docs.isNotEmpty) {
        final adminDoc = adminQuery.docs.first;
        await adminDoc.reference.update({
          'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      print('Error updating last login: $e');
    }
  }
  
  // Content Management Methods
  
  // Add content (banners, ads, events, etc.)
  static Future<String?> addContent(AdminContent content) async {
    if (!await isAdmin()) {
      throw Exception('Only admins can add content');
    }
    
    try {
      final docRef = await _firestore
          .collection(contentCollection)
          .add(content.toJson());
      
      return docRef.id;
    } catch (e) {
      print('Error adding content: $e');
      return null;
    }
  }
  
  // Update content
  static Future<bool> updateContent(String contentId, AdminContent content) async {
    if (!await isAdmin()) {
      throw Exception('Only admins can update content');
    }
    
    try {
      await _firestore
          .collection(contentCollection)
          .doc(contentId)
          .update(content.toJson());
      
      return true;
    } catch (e) {
      print('Error updating content: $e');
      return false;
    }
  }
  
  // Delete content
  static Future<bool> deleteContent(String contentId) async {
    if (!await isAdmin()) {
      throw Exception('Only admins can delete content');
    }
    
    try {
      await _firestore
          .collection(contentCollection)
          .doc(contentId)
          .delete();
      
      return true;
    } catch (e) {
      print('Error deleting content: $e');
      return false;
    }
  }
  
  // Get content by type and status
  static Future<List<AdminContent>> getContent({
    String? type,
    bool? isActive,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(contentCollection)
          .orderBy('createdAt', descending: true);
      
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      
      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }
      
      final querySnapshot = await query.limit(limit).get();
      
      return querySnapshot.docs
          .map((doc) => AdminContent.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting content: $e');
      return [];
    }
  }
  
  // Get content stream for real-time updates
  static Stream<List<AdminContent>> getContentStream({
    String? type,
    bool? isActive,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection(contentCollection)
        .orderBy('createdAt', descending: true);
    
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }
    
    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminContent.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    });
  }
}

// Content Types Constants
class ContentTypes {
  static const String banner = 'banner';
  static const String ad = 'ad';
  static const String event = 'event';
  static const String news = 'news';
  static const String announcement = 'announcement';
  static const String schedule = 'schedule';
  static const String promotion = 'promotion';
}
