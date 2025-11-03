import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../provider/admin_provider.dart';
import '../../models/admin_role.dart';
import 'admin_dashboard_screen.dart';
import 'finance_admin_screen.dart';
import 'updates_admin_screen.dart';

/// Role-aware admin dashboard that routes to appropriate screen based on admin type
class RoleBasedAdminDashboard extends StatelessWidget {
  const RoleBasedAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        // Show loading state
        if (adminProvider.isLoading) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF006833)),
                  const SizedBox(height: 16),
                  Text(
                    'Verifying admin access...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user is authorized admin
        if (!adminProvider.isAdmin) {
          return _buildUnauthorizedScreen(context);
        }

        // Route to role-specific dashboard
        final role = adminProvider.adminRole;
        
        switch (role) {
          case AdminRole.superAdmin:
            return const AdminDashboardScreen(); // Full access
          
          case AdminRole.financeAdmin:
            return const FinanceAdminScreen(); // Finance only
          
          case AdminRole.updatesAdmin:
            return const UpdatesAdminScreen(); // Content updates only
          
          default:
            // Fallback for legacy admins
            if (adminProvider.isSuperAdmin) {
              return const AdminDashboardScreen();
            }
            return _buildUnauthorizedScreen(context);
        }
      },
    );
  }

  Widget _buildUnauthorizedScreen(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Access Denied',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Unauthorized Access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your account (${user?.email ?? 'Unknown'}) does not have admin privileges.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Only authorized admin accounts can access this area.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text(
                'Authorized Admin Accounts:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildAdminEmailChip(
                email: AdminPermissions.superAdminEmail,
                role: 'Super Admin',
                color: const Color(0xFF006833),
              ),
              const SizedBox(height: 8),
              _buildAdminEmailChip(
                email: AdminPermissions.financeAdminEmail,
                role: 'Finance Admin',
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              _buildAdminEmailChip(
                email: AdminPermissions.updatesAdminEmail,
                role: 'Updates Admin',
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminEmailChip({
    required String email,
    required String role,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
