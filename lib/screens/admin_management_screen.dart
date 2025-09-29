import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feather_icons/feather_icons.dart';
import '../provider/admin_provider.dart';
import '../models/admin_models.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Admin Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006833),
              ),
            );
          }

          if (!adminProvider.isSuperAdmin) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FeatherIcons.shield,
                    color: Colors.grey[600],
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only super admin can manage admins',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Admin Section
                _buildAddAdminSection(adminProvider),
                
                const SizedBox(height: 32),
                
                // Current Admins List
                _buildAdminsListSection(adminProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddAdminSection(AdminProvider adminProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF006833).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FeatherIcons.userPlus,
                color: const Color(0xFF006833),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Add New Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Enter the email address of the user you want to grant admin privileges.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
          
          const SizedBox(height: 16),
          
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lato',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontFamily: 'Lato',
                    ),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF006833),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      FeatherIcons.mail,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAdding ? null : () => _addAdmin(adminProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006833),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isAdding
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add Admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Lato',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminsListSection(AdminProvider adminProvider) {
    final admins = adminProvider.allAdmins;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              FeatherIcons.users,
              color: const Color(0xFF006833),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Current Admins',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF006833).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${admins.length} admin${admins.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Color(0xFF006833),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (admins.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    FeatherIcons.userX,
                    color: Colors.grey[600],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No admins found',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add the first admin to get started',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...admins.map((admin) => _buildAdminCard(admin, adminProvider)).toList(),
      ],
    );
  }

  Widget _buildAdminCard(AdminUser admin, AdminProvider adminProvider) {
    final isSuperAdmin = admin.email.toLowerCase() == 'yerinssaibs@gmail.com';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuperAdmin 
              ? const Color(0xFF006833).withOpacity(0.5)
              : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Admin avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSuperAdmin
                  ? const Color(0xFF006833).withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSuperAdmin
                    ? const Color(0xFF006833)
                    : Colors.blue,
                width: 1,
              ),
            ),
            child: Icon(
              isSuperAdmin ? FeatherIcons.star : FeatherIcons.user,
              color: isSuperAdmin
                  ? const Color(0xFF006833)
                  : Colors.blue,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Admin details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      admin.email,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                      ),
                    ),
                    if (isSuperAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006833).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SUPER',
                          style: TextStyle(
                            color: Color(0xFF006833),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      admin.isActive ? FeatherIcons.checkCircle : FeatherIcons.xCircle,
                      color: admin.isActive ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      admin.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: admin.isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      FeatherIcons.clock,
                      color: Colors.grey[600],
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      admin.lastLoginAt != null
                          ? _formatDate(admin.lastLoginAt!)
                          : 'Never',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          if (!isSuperAdmin && admin.isActive)
            PopupMenuButton<String>(
              icon: Icon(
                FeatherIcons.moreVertical,
                color: Colors.grey[600],
                size: 20,
              ),
              color: Colors.grey[800],
              onSelected: (value) {
                if (value == 'remove') {
                  _confirmRemoveAdmin(admin, adminProvider);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(
                        FeatherIcons.userX,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remove Admin',
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _addAdmin(AdminProvider adminProvider) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isAdding = true;
    });
    
    try {
      final email = _emailController.text.trim();
      final success = await adminProvider.addAdmin(email);
      
      if (success) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin added successfully: $email'),
            backgroundColor: const Color(0xFF006833),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add admin. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  void _confirmRemoveAdmin(AdminUser admin, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Remove Admin',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove admin privileges from:',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              admin.email,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    FeatherIcons.alertTriangle,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 12,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'Lato',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await adminProvider.removeAdmin(admin.id);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Admin removed: ${admin.email}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to remove admin'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontFamily: 'Lato'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
