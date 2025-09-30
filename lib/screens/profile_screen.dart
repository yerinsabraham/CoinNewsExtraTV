import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:feather_icons/feather_icons.dart';
import '../services/auth_service.dart';
import '../services/user_balance_service.dart';
import '../services/reward_service.dart';
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

  // Show Watch History Dialog
  void _showWatchHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Watch History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getWatchHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF006833)),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading watch history: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              final watchHistory = snapshot.data ?? [];
              
              if (watchHistory.isEmpty) {
                return const Center(
                  child: Text(
                    'No watch history yet.\nStart watching videos to see them here!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: watchHistory.length,
                itemBuilder: (context, index) {
                  final video = watchHistory[index];
                  return ListTile(
                    leading: Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                    title: Text(
                      video['title'] ?? 'Video ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatWatchDate(video['watchedAt']),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    trailing: Text(
                      '${video['duration'] ?? '0:00'}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  );
                },
              );
            },
          ),
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

  // Show Liked Videos Dialog
  void _showLikedVideos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Liked Videos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getLikedVideos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF006833)),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading liked videos: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              final likedVideos = snapshot.data ?? [];
              
              if (likedVideos.isEmpty) {
                return const Center(
                  child: Text(
                    'No liked videos yet.\nStart liking videos to see them here!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: likedVideos.length,
                itemBuilder: (context, index) {
                  final video = likedVideos[index];
                  return ListTile(
                    leading: Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.red),
                    ),
                    title: Text(
                      video['title'] ?? 'Video ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatWatchDate(video['likedAt']),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.favorite_border,
                      color: Colors.red,
                      size: 16,
                    ),
                  );
                },
              );
            },
          ),
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

  // Show Earnings History Dialog
  void _showEarningsHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Earnings History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getEarningsHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF006833)),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading earnings history: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              final earnings = snapshot.data ?? [];
              
              if (earnings.isEmpty) {
                return const Center(
                  child: Text(
                    'No earnings history yet.\nStart earning CNE tokens to see transactions here!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: earnings.length,
                itemBuilder: (context, index) {
                  final transaction = earnings[index];
                  final isPositive = (transaction['amount'] ?? 0.0) > 0;
                  
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green[700] : Colors.red[700],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPositive ? Icons.add : Icons.remove,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      transaction['source'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      _formatWatchDate(transaction['timestamp']),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    trailing: Text(
                      '${isPositive ? '+' : ''}${(transaction['amount'] ?? 0.0).toStringAsFixed(2)} CNE',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          ),
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

  // Fetch watch history from Firestore
  Future<List<Map<String, dynamic>>> _getWatchHistory() async {
    try {
      // Simulate watch history for now - in production this would come from Firestore
      // You would query something like: users/{userId}/watch_history
      await Future.delayed(const Duration(milliseconds: 500));
      
      return [
        {
          'videoId': 'video1',
          'title': 'Bitcoin Price Analysis Today',
          'duration': '5:32',
          'watchedAt': DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        },
        {
          'videoId': 'video2', 
          'title': 'Ethereum vs Cardano: Which is Better?',
          'duration': '8:15',
          'watchedAt': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        },
        {
          'videoId': 'video3',
          'title': 'DeFi Explained for Beginners',
          'duration': '12:05',
          'watchedAt': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
        },
      ];
    } catch (e) {
      print('Error fetching watch history: $e');
      return [];
    }
  }

  // Fetch liked videos from Firestore
  Future<List<Map<String, dynamic>>> _getLikedVideos() async {
    try {
      // Simulate liked videos for now - in production this would come from Firestore
      // You would query something like: users/{userId}/liked_videos
      await Future.delayed(const Duration(milliseconds: 500));
      
      return [
        {
          'videoId': 'video1',
          'title': 'Top 10 Cryptocurrencies to Watch',
          'likedAt': DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
        },
        {
          'videoId': 'video4',
          'title': 'NFT Market Analysis 2024',
          'likedAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        },
      ];
    } catch (e) {
      print('Error fetching liked videos: $e');
      return [];
    }
  }

  // Fetch earnings history from Firestore
  Future<List<Map<String, dynamic>>> _getEarningsHistory() async {
    try {
      // Get actual transaction history from RewardService
      final transactions = await RewardService.getTransactionHistory(limit: 20);
      
      if (transactions != null && transactions.isNotEmpty) {
        return transactions.map((t) => {
          'source': _getTransactionSourceName(t['eventType'] ?? 'unknown'),
          'amount': (t['amount'] ?? 0.0) is int 
              ? (t['amount'] as int).toDouble() 
              : (t['amount'] ?? 0.0),
          'timestamp': t['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
        }).toList();
      }
      
      // Fallback to simulated data if no real data
      await Future.delayed(const Duration(milliseconds: 500));
      
      return [
        {
          'source': 'Video Watch',
          'amount': 5.0,
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        },
        {
          'source': 'Daily Check-in',
          'amount': 10.0,
          'timestamp': DateTime.now().subtract(const Duration(hours: 8)).millisecondsSinceEpoch,
        },
        {
          'source': 'Quiz Penalty',
          'amount': -2.0,
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        },
        {
          'source': 'Social Media Follow',
          'amount': 3.0,
          'timestamp': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        },
        {
          'source': 'Quiz Entry Fee',
          'amount': -5.0,
          'timestamp': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        },
      ];
    } catch (e) {
      print('Error fetching earnings history: $e');
      return [];
    }
  }

  // Helper method to format dates
  String _formatWatchDate(dynamic timestamp) {
    try {
      late DateTime date;
      if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Unknown date';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  // Helper method to get user-friendly transaction source names
  String _getTransactionSourceName(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'video_watch':
        return 'Video Watch';
      case 'daily_airdrop':
        return 'Daily Check-in';
      case 'social_follow':
        return 'Social Media Follow';
      case 'quiz_completion':
        return 'Quiz Reward';
      case 'quiz_entry_fee':
        return 'Quiz Entry Fee';
      case 'quiz_penalty':
        return 'Quiz Penalty';
      case 'ad_view':
        return 'Ad View';
      case 'live_stream':
        return 'Live Stream';
      case 'signup':
        return 'Signup Bonus';
      case 'referral_bonus':
        return 'Referral Bonus';
      default:
        return eventType.replaceAll('_', ' ').toUpperCase();
    }
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
                  Consumer<UserBalanceService>(
                    builder: (context, balanceService, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Videos Watched', '${balanceService.earningStats.videosWatched}'),
                          Container(width: 1, height: 40, color: Colors.grey[700]),
                          _buildStatItem('Rewards Earned', '\$${balanceService.balance.totalUsdValue.toStringAsFixed(2)}'),
                          Container(width: 1, height: 40, color: Colors.grey[700]),
                          _buildStreakDaysItem(),
                        ],
                      );
                    },
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
                        Consumer<UserBalanceService>(
                          builder: (context, balanceService, child) {
                            return Text(
                              '\$${balanceService.balance.totalUsdValue.toStringAsFixed(2)} USD',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            );
                          },
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
                    
                    // Delete User Account (Super Admin Only)
                    if (adminProvider.isSuperAdmin)
                      _buildMenuOption(
                        icon: FeatherIcons.userX,
                        title: 'Delete User Account',
                        subtitle: 'Permanently delete user accounts (DANGER)',
                        onTap: () {
                          Navigator.pushNamed(context, '/admin-delete-user');
                        },
                        isAdmin: true,
                        isDangerous: true,
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
              onTap: () => _showWatchHistory(),
            ),
            _buildMenuOption(
              icon: Icons.favorite_border,
              title: 'Liked Videos',
              subtitle: 'Videos you\'ve liked',
              onTap: () => _showLikedVideos(),
            ),
            _buildMenuOption(
              icon: Icons.money_outlined,
              title: 'Earnings History',
              subtitle: 'Track your rewards and earnings',
              onTap: () => _showEarningsHistory(),
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
    bool isDangerous = false,
  }) {
    final Color iconColor = isDangerous 
        ? Colors.red 
        : (isAdmin ? const Color(0xFF006833) : Colors.white);
    final Color trailingColor = isDangerous 
        ? Colors.red 
        : (isAdmin ? const Color(0xFF006833) : Colors.grey);
    final Color? tileColor = isDangerous 
        ? Colors.red.withOpacity(0.1)
        : (isAdmin ? const Color(0xFF006833).withOpacity(0.1) : Colors.grey[900]);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDangerous ? Colors.red : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Lato',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDangerous ? Colors.red[300] : Colors.grey[400],
            fontSize: 14,
            fontFamily: 'Lato',
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: trailingColor,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: tileColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  Widget _buildStreakDaysItem() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: RewardService.getDailyRewardStatus(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final currentStreak = data?['currentStreak'] ?? 0;
        
        return _buildStatItem('Streak Days', '$currentStreak');
      },
    );
  }
}
