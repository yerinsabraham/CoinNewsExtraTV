import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../provider/admin_provider.dart';
import 'package:provider/provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'User Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.userPlus, color: Colors.white),
            onPressed: _showCreateUserDialog,
            tooltip: 'Create User',
          ),
          IconButton(
            icon: const Icon(FeatherIcons.settings, color: Colors.white),
            onPressed: _showUserSettingsDialog,
            tooltip: 'User Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF006833),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          labelStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(FeatherIcons.users), text: 'All Users'),
            Tab(icon: Icon(FeatherIcons.shield), text: 'Admins'),
            Tab(icon: Icon(FeatherIcons.userX), text: 'Suspended'),
            Tab(icon: Icon(FeatherIcons.activity), text: 'Active'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllUsersTab(),
                _buildAdminsTab(),
                _buildSuspendedUsersTab(),
                _buildActiveUsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        style: const TextStyle(color: Colors.white, fontFamily: 'Lato'),
        decoration: InputDecoration(
          hintText: 'Search users by name, email...',
          hintStyle: TextStyle(color: Colors.grey[500], fontFamily: 'Lato'),
          prefixIcon: Icon(FeatherIcons.search, color: Colors.grey[500]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(FeatherIcons.x, color: Colors.grey[500]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAllUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading users: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final users = snapshot.data?.docs ?? [];
        final filteredUsers = _filterUsers(users);

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(
            icon: FeatherIcons.users,
            title: 'No Users Found',
            subtitle: _searchQuery.isNotEmpty 
                ? 'No users match your search criteria'
                : 'No users registered yet',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final userData = user.data() as Map<String, dynamic>;
            return _buildUserCard(user.id, userData);
          },
        );
      },
    );
  }

  Widget _buildAdminsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading admins: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final admins = snapshot.data?.docs ?? [];
        final filteredAdmins = _filterUsers(admins);

        if (filteredAdmins.isEmpty) {
          return _buildEmptyState(
            icon: FeatherIcons.shield,
            title: 'No Admins Found',
            subtitle: _searchQuery.isNotEmpty 
                ? 'No admins match your search criteria'
                : 'No admins configured',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredAdmins.length,
          itemBuilder: (context, index) {
            final admin = filteredAdmins[index];
            final adminData = admin.data() as Map<String, dynamic>;
            return _buildAdminCard(admin.id, adminData);
          },
        );
      },
    );
  }

  Widget _buildSuspendedUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: false)
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading suspended users: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final users = snapshot.data?.docs ?? [];
        final filteredUsers = _filterUsers(users);

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(
            icon: FeatherIcons.userX,
            title: 'No Suspended Users',
            subtitle: _searchQuery.isNotEmpty 
                ? 'No suspended users match your search'
                : 'No users are currently suspended',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final userData = user.data() as Map<String, dynamic>;
            return _buildUserCard(user.id, userData, isSuspended: true);
          },
        );
      },
    );
  }

  Widget _buildActiveUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('lastLoginAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading active users: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final users = snapshot.data?.docs ?? [];
        final filteredUsers = _filterUsers(users);

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(
            icon: FeatherIcons.activity,
            title: 'No Active Users',
            subtitle: _searchQuery.isNotEmpty 
                ? 'No active users match your search'
                : 'No users are currently active',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final userData = user.data() as Map<String, dynamic>;
            return _buildUserCard(user.id, userData);
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final name = (userData['displayName'] ?? userData['username'] ?? '').toString().toLowerCase();
      final email = (userData['email'] ?? '').toString().toLowerCase();
      
      return name.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData, {bool isSuspended = false}) {
    final name = userData['displayName'] ?? userData['username'] ?? 'Unknown User';
    final email = userData['email'] ?? 'No email';
    final isActive = userData['isActive'] ?? true;
    final createdAt = userData['createdAt'] as Timestamp?;
    final lastLoginAt = userData['lastLoginAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuspended 
              ? Colors.red.withOpacity(0.3)
              : isActive 
                  ? const Color(0xFF006833).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isSuspended 
                    ? Colors.red.withOpacity(0.2)
                    : const Color(0xFF006833).withOpacity(0.2),
                child: Icon(
                  isSuspended ? FeatherIcons.userX : FeatherIcons.user,
                  color: isSuspended ? Colors.red : const Color(0xFF006833),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
              _buildUserStatusBadge(isActive, isSuspended),
              PopupMenuButton<String>(
                icon: const Icon(FeatherIcons.moreVertical, color: Colors.white),
                color: Colors.grey[800],
                onSelected: (value) => _handleUserAction(value, userId, userData),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(FeatherIcons.edit, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text('Edit User', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: isActive ? 'suspend' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? FeatherIcons.userX : FeatherIcons.userCheck,
                          color: isActive ? Colors.red : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Suspend User' : 'Activate User',
                          style: TextStyle(
                            color: isActive ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'permissions',
                    child: Row(
                      children: [
                        Icon(FeatherIcons.key, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text('Permissions', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(FeatherIcons.trash2, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text('Delete User', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: FeatherIcons.calendar,
                label: 'Joined: ${_formatDate(createdAt)}',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: FeatherIcons.clock,
                label: 'Last login: ${_formatDate(lastLoginAt)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(String adminId, Map<String, dynamic> adminData) {
    final email = adminData['email'] ?? 'No email';
    final isSuperAdmin = adminData['isSuperAdmin'] ?? false;
    final permissions = adminData['permissions'] as List<dynamic>? ?? [];
    final createdAt = adminData['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuperAdmin 
              ? Colors.amber.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isSuperAdmin 
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                child: Icon(
                  isSuperAdmin ? FeatherIcons.star : FeatherIcons.shield,
                  color: isSuperAdmin ? Colors.amber : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                        if (isSuperAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SUPER',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${permissions.length} permission${permissions.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSuperAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(FeatherIcons.moreVertical, color: Colors.white),
                  color: Colors.grey[800],
                  onSelected: (value) => _handleAdminAction(value, adminId, adminData),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(FeatherIcons.edit, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Permissions', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(FeatherIcons.userMinus, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Remove Admin', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: permissions.map((permission) => 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  permission.toString(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Added: ${_formatDate(createdAt)}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusBadge(bool isActive, bool isSuspended) {
    Color color;
    String text;
    
    if (isSuspended) {
      color = Colors.red;
      text = 'Suspended';
    } else if (isActive) {
      color = Colors.green;
      text = 'Active';
    } else {
      color = Colors.grey;
      text = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Lato',
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[400], size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF006833)),
          SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FeatherIcons.alertTriangle,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleUserAction(String action, String userId, Map<String, dynamic> userData) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(userId, userData);
        break;
      case 'suspend':
        _showSuspendUserDialog(userId, userData);
        break;
      case 'activate':
        _activateUser(userId);
        break;
      case 'permissions':
        _showUserPermissionsDialog(userId, userData);
        break;
      case 'delete':
        _showDeleteUserDialog(userId, userData);
        break;
    }
  }

  void _handleAdminAction(String action, String adminId, Map<String, dynamic> adminData) {
    switch (action) {
      case 'edit':
        _showEditAdminDialog(adminId, adminData);
        break;
      case 'remove':
        _showRemoveAdminDialog(adminId, adminData);
        break;
    }
  }

  void _showCreateUserDialog() {
    // Implementation for creating new user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Create New User',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: const Text(
          'User creation functionality coming soon!',
          style: TextStyle(color: Colors.grey, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF006833)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserSettingsDialog() {
    // Implementation for user settings
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'User Settings',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: const Text(
          'User settings panel coming soon!',
          style: TextStyle(color: Colors.grey, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF006833)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(String userId, Map<String, dynamic> userData) {
    // Implementation for editing user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit User',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'Edit user: ${userData['displayName'] ?? userData['email']}',
          style: const TextStyle(color: Colors.grey, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF006833)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuspendUserDialog(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Suspend User',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'Are you sure you want to suspend ${userData['displayName'] ?? userData['email']}?',
          style: const TextStyle(color: Colors.grey, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _suspendUser(userId);
              Navigator.pop(context);
            },
            child: const Text(
              'Suspend',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete User',
          style: TextStyle(color: Colors.red, fontFamily: 'Lato'),
        ),
        content: Text(
          'Are you sure you want to permanently delete ${userData['displayName'] ?? userData['email']}? This action cannot be undone.',
          style: const TextStyle(color: Colors.grey, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for deleting user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User deletion not implemented yet'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserPermissionsDialog(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'User Permissions',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'Manage permissions for: ${userData['displayName'] ?? userData['email']}',
          style: const TextStyle(color: Colors.grey, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF006833)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAdminDialog(String adminId, Map<String, dynamic> adminData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit Admin Permissions',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'Edit permissions for: ${adminData['email']}',
          style: const TextStyle(color: Colors.grey, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF006833)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveAdminDialog(String adminId, Map<String, dynamic> adminData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Remove Admin',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'Are you sure you want to remove admin privileges from ${adminData['email']}?',
          style: const TextStyle(color: Colors.grey, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _removeAdmin(adminId);
              Navigator.pop(context);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _suspendUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': false,
        'suspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User suspended successfully'),
            backgroundColor: Color(0xFF006833),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error suspending user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activateUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': true,
        'suspendedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User activated successfully'),
            backgroundColor: Color(0xFF006833),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error activating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAdmin(String adminId) async {
    try {
      final adminProvider = context.read<AdminProvider>();
      await adminProvider.removeAdmin(adminId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin removed successfully'),
            backgroundColor: Color(0xFF006833),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing admin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}