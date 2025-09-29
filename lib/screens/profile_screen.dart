import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:feather_icons/feather_icons.dart';
import '../services/auth_service.dart';
import '../provider/admin_provider.dart';
import 'login_screen.dart';
import 'admin_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.initializeAdminStatus();
    });
  }

  void _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF006833),
                    backgroundImage: currentUser?.photoURL != null 
                        ? NetworkImage(currentUser!.photoURL!) 
                        : null,
                    child: currentUser?.photoURL == null
                        ? Text(
                            currentUser?.displayName?.isNotEmpty == true 
                                ? currentUser!.displayName![0].toUpperCase()
                                : currentUser?.email?.isNotEmpty == true
                                    ? currentUser!.email![0].toUpperCase()
                                    : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    currentUser?.displayName ?? 'Anonymous User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email
                  Text(
                    currentUser?.email ?? 'No email',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Videos Watched', '15'),
                      Container(width: 1, height: 40, color: Colors.grey[700]),
                      _buildStatItem('Rewards Earned', '\$12.50'),
                      Container(width: 1, height: 40, color: Colors.grey[700]),
                      _buildStatItem('Streak Days', '7'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Wallet Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF006833).withOpacity(0.1),
                    const Color(0xFF006833).withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: const Color(0xFF006833)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF006833),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$12.50 USD',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Withdraw feature coming soon!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006833),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Withdraw'),
                  ),
                ],
              ),
            ),

            // Admin Section (only visible to admins)
            Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                if (adminProvider.isLoading) {
                  return const SizedBox(height: 16);
                }
                
                if (!adminProvider.isAdmin) {
                  return const SizedBox(height: 16);
                }
                
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    // Admin Badge
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF006833).withOpacity(0.2),
                            const Color(0xFF006833).withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(color: const Color(0xFF006833)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            adminProvider.isSuperAdmin ? FeatherIcons.star : FeatherIcons.shield,
                            color: const Color(0xFF006833),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminProvider.isSuperAdmin ? 'Super Admin' : 'Admin',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                                Text(
                                  adminProvider.isSuperAdmin 
                                      ? 'Full administrative privileges'
                                      : 'Content management privileges',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Admin Management (Super Admin Only)
                    if (adminProvider.isSuperAdmin)
                      _buildMenuOption(
                        icon: FeatherIcons.userPlus,
                        title: 'Admin Management',
                        subtitle: 'Add or remove admin users',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminManagementScreen(),
                            ),
                          );
                        },
                        isAdmin: true,
                      ),
                    
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),

            // Menu Options
            _buildMenuOption(
              icon: Icons.history,
              title: 'Watch History',
              subtitle: 'See your previously watched videos',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Watch history coming soon!')),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.favorite_border,
              title: 'Liked Videos',
              subtitle: 'Videos you\'ve liked',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Liked videos coming soon!')),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.download_outlined,
              title: 'Downloads',
              subtitle: 'Your offline videos',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloads coming soon!')),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.money_outlined,
              title: 'Earnings History',
              subtitle: 'Track your rewards and earnings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Earnings history coming soon!')),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & support coming soon!')),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App version and information',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text(
                      'About CoinNewsExtra TV',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'CoinNewsExtra TV v1.0.0\n\nWatch cryptocurrency and blockchain content while earning rewards.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Sign Out Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF006833),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isAdmin = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isAdmin ? const Color(0xFF006833) : Colors.white,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Lato',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontFamily: 'Lato',
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isAdmin ? const Color(0xFF006833) : Colors.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: isAdmin 
            ? const Color(0xFF006833).withOpacity(0.1) 
            : Colors.grey[900],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}
