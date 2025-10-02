// Test file for Admin System
// This is a temporary test file to verify admin functionality

import 'services/admin_service.dart';
import 'models/admin_models.dart';

class AdminSystemTest {
  static Future<void> runTests() async {
    print('=== Admin System Tests ===');
    
    // Test 1: Check super admin status
    print('Test 1: Super Admin Check');
    bool isSuperAdmin = AdminService.isSuperAdmin();
    print('Super Admin Status: $isSuperAdmin');
    
    // Test 2: Check admin status
    print('\nTest 2: Admin Status Check');
    try {
      bool isAdmin = await AdminService.isAdmin();
      print('Admin Status: $isAdmin');
    } catch (e) {
      print('Error checking admin status: $e');
    }
    
    // Test 3: Create test admin content
    print('\nTest 3: Create Test Content');
    try {
      AdminContent testContent = AdminContent(
        id: 'test-banner-1',
        type: ContentTypes.banner,
        title: 'Test Banner',
        description: 'This is a test banner created by admin system',
        imageUrl: 'https://via.placeholder.com/400x200/006833/FFFFFF?text=Test+Banner',
        data: {},
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin-test',
      );
      
      String? contentId = await AdminService.addContent(testContent);
      if (contentId != null) {
        print('Test content created successfully with ID: $contentId');
      } else {
        print('Failed to create test content');
      }
    } catch (e) {
      print('Error creating test content: $e');
    }
    
    // Test 4: Retrieve content
    print('\nTest 4: Retrieve Content');
    try {
      List<AdminContent> banners = await AdminService.getContent(type: ContentTypes.banner);
      print('Retrieved ${banners.length} banners');
      for (var banner in banners) {
        print('Banner: ${banner.title} - Active: ${banner.isActive}');
      }
    } catch (e) {
      print('Error retrieving content: $e');
    }
    
    print('\n=== Admin System Tests Complete ===');
  }
}
