import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AdminProvider extends ChangeNotifier {
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _isLoading = true;
  List<AdminUser> _allAdmins = [];
  
  bool get isAdmin => _isAdmin;
  bool get isSuperAdmin => _isSuperAdmin;
  bool get isLoading => _isLoading;
  List<AdminUser> get allAdmins => _allAdmins;
  
  AdminProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _checkAdminStatus();
    
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _isAdmin = false;
        _isSuperAdmin = false;
        _allAdmins = [];
        notifyListeners();
      } else {
        _checkAdminStatus();
      }
    });
  }

  // Public method to initialize admin status
  Future<void> initializeAdminStatus() async {
    await _checkAdminStatus();
  }
  
  Future<void> _checkAdminStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _isSuperAdmin = AdminService.isSuperAdmin();
      _isAdmin = await AdminService.isAdmin();
      
      if (_isSuperAdmin) {
        await _loadAllAdmins();
      }
      
      // Update last login if user is admin
      if (_isAdmin) {
        await AdminService.updateLastLogin();
      }
    } catch (e) {
      print('Error checking admin status: $e');
      _isAdmin = false;
      _isSuperAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadAllAdmins() async {
    try {
      _allAdmins = await AdminService.getAllAdmins();
      notifyListeners();
    } catch (e) {
      print('Error loading admins: $e');
    }
  }
  
  Future<bool> addAdmin(String email) async {
    if (!_isSuperAdmin) return false;
    
    try {
      final success = await AdminService.addAdmin(email);
      if (success) {
        await _loadAllAdmins();
      }
      return success;
    } catch (e) {
      print('Error adding admin: $e');
      return false;
    }
  }
  
  Future<bool> removeAdmin(String adminId) async {
    if (!_isSuperAdmin) return false;
    
    try {
      final success = await AdminService.removeAdmin(adminId);
      if (success) {
        await _loadAllAdmins();
      }
      return success;
    } catch (e) {
      print('Error removing admin: $e');
      return false;
    }
  }
  
  Future<void> refreshAdminStatus() async {
    await _checkAdminStatus();
  }
}

class AdminContentProvider extends ChangeNotifier {
  final Map<String, List<AdminContent>> _contentByType = {};
  final Map<String, bool> _loadingStates = {};
  
  List<AdminContent> getContentByType(String type) {
    return _contentByType[type] ?? [];
  }
  
  bool isLoadingContent(String type) {
    return _loadingStates[type] ?? false;
  }
  
  Future<void> loadContent(String type, {bool forceRefresh = false}) async {
    if (_loadingStates[type] == true && !forceRefresh) return;
    
    _loadingStates[type] = true;
    notifyListeners();
    
    try {
      final content = await AdminService.getContent(
        type: type,
        isActive: true,
      );
      _contentByType[type] = content;
    } catch (e) {
      print('Error loading content for type $type: $e');
    } finally {
      _loadingStates[type] = false;
      notifyListeners();
    }
  }
  
  Future<String?> addContent(AdminContent content) async {
    try {
      final contentId = await AdminService.addContent(content);
      if (contentId != null) {
        // Refresh the content list for this type
        await loadContent(content.type, forceRefresh: true);
      }
      return contentId;
    } catch (e) {
      print('Error adding content: $e');
      return null;
    }
  }
  
  Future<bool> updateContent(String contentId, AdminContent content) async {
    try {
      final success = await AdminService.updateContent(contentId, content);
      if (success) {
        // Refresh the content list for this type
        await loadContent(content.type, forceRefresh: true);
      }
      return success;
    } catch (e) {
      print('Error updating content: $e');
      return false;
    }
  }
  
  Future<bool> deleteContent(String contentId, String type) async {
    try {
      final success = await AdminService.deleteContent(contentId);
      if (success) {
        // Refresh the content list for this type
        await loadContent(type, forceRefresh: true);
      }
      return success;
    } catch (e) {
      print('Error deleting content: $e');
      return false;
    }
  }
  
  Stream<List<AdminContent>> getContentStream(String type) {
    return AdminService.getContentStream(
      type: type,
      isActive: true,
    );
  }
}
