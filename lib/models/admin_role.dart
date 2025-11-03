// Admin Role Models and Permissions
// Defines the three-tier admin system for CoinNewsExtraTV

enum AdminRole {
  superAdmin,
  financeAdmin,
  updatesAdmin,
}

class AdminUser {
  final String uid;
  final String email;
  final AdminRole role;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;

  AdminUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
  });

  factory AdminUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AdminUser(
      uid: uid,
      email: data['email'] as String,
      role: _roleFromString(data['role'] as String? ?? 'updates_admin'),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as dynamic)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role.toStringValue(),
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'isActive': isActive,
    };
  }

  static AdminRole _roleFromString(String roleStr) {
    switch (roleStr) {
      case 'super_admin':
        return AdminRole.superAdmin;
      case 'finance_admin':
        return AdminRole.financeAdmin;
      case 'updates_admin':
        return AdminRole.updatesAdmin;
      default:
        return AdminRole.updatesAdmin;
    }
  }
}

extension AdminRoleExtension on AdminRole {
  String toStringValue() {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.financeAdmin:
        return 'finance_admin';
      case AdminRole.updatesAdmin:
        return 'updates_admin';
    }
  }

  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.financeAdmin:
        return 'Finance Admin';
      case AdminRole.updatesAdmin:
        return 'Updates Admin';
    }
  }

  String get description {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Full system access and admin management';
      case AdminRole.financeAdmin:
        return 'CNE token and finance management only';
      case AdminRole.updatesAdmin:
        return 'Content updates and maintenance';
    }
  }
}

class AdminPermissions {
  // Authorized admin accounts - MUST match these exact emails
  static const String superAdminEmail = 'cnesup@outlook.com';
  static const String financeAdminEmail = 'cnefinance@outlook.com';
  static const String updatesAdminEmail = 'cneupdates@gmail.com';
  
  // Default password for all admin accounts
  static const String defaultPassword = 'cneadmin1234';

  // Get admin role from email
  static AdminRole? getRoleFromEmail(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    
    if (normalizedEmail == superAdminEmail.toLowerCase()) {
      return AdminRole.superAdmin;
    } else if (normalizedEmail == financeAdminEmail.toLowerCase()) {
      return AdminRole.financeAdmin;
    } else if (normalizedEmail == updatesAdminEmail.toLowerCase()) {
      return AdminRole.updatesAdmin;
    }
    
    return null; // Not an authorized admin
  }

  // Check if email is authorized admin
  static bool isAuthorizedAdmin(String email) {
    return getRoleFromEmail(email) != null;
  }

  // Permission checks
  static bool canManageAdmins(AdminRole role) {
    return role == AdminRole.superAdmin;
  }

  static bool canManageFinance(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.financeAdmin;
  }

  static bool canSendTokens(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.financeAdmin;
  }

  static bool canViewTransactionLogs(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.financeAdmin;
  }

  static bool canManageContent(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.updatesAdmin;
  }

  static bool canUploadVideos(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.updatesAdmin;
  }

  static bool canManagePrograms(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.updatesAdmin;
  }

  static bool canManageSchedules(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.updatesAdmin;
  }

  static bool canManageSpotlight(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.updatesAdmin;
  }

  static bool canManageQuiz(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.updatesAdmin;
  }

  static bool canModerateComments(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.updatesAdmin;
  }

  static bool canManageNews(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.updatesAdmin;
  }

  static bool canUpdateHomepage(AdminRole role) {
    return role == AdminRole.superAdmin || role == AdminRole.updatesAdmin;
  }

  static bool canAccessSystemSettings(AdminRole role) {
    return role == AdminRole.superAdmin;
  }

  static bool canViewUserManagement(AdminRole role) {
    return role == AdminRole.superAdmin;
  }

  static bool canManageSupport(AdminRole role) {
    return role == AdminRole.superAdmin;
  }

  // Get all permissions for a role
  static List<String> getPermissionsForRole(AdminRole role) {
    final permissions = <String>[];

    switch (role) {
      case AdminRole.superAdmin:
        permissions.addAll([
          'manage_admins',
          'manage_finance',
          'send_tokens',
          'view_transaction_logs',
          'manage_content',
          'upload_videos',
          'manage_programs',
          'manage_schedules',
          'manage_spotlight',
          'manage_quiz',
          'moderate_comments',
          'manage_news',
          'update_homepage',
          'system_settings',
          'user_management',
          'support_management',
        ]);
        break;

      case AdminRole.financeAdmin:
        permissions.addAll([
          'manage_finance',
          'send_tokens',
          'view_transaction_logs',
        ]);
        break;

      case AdminRole.updatesAdmin:
        permissions.addAll([
          'manage_content',
          'upload_videos',
          'manage_programs',
          'manage_schedules',
          'manage_spotlight',
          'manage_quiz',
          'moderate_comments',
          'manage_news',
          'update_homepage',
        ]);
        break;
    }

    return permissions;
  }
}
