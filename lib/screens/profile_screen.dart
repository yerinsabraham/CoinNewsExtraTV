import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/user_balance_service.dart';
import '../provider/admin_provider.dart';
import '../data/video_data.dart';
import '../models/video_model.dart';
import '../help_support/screens/help_support_screen.dart';
import '../admin/screens/role_based_admin_dashboard.dart';
import 'login_screen.dart';
import 'settings_page.dart';
import 'contact_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.initializeAdminStatus();
    });
    _loadPersistedProfile();
    _ensureReferralCode();
  }

  Future<void> _ensureReferralCode() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snap = await docRef.get();
      if (snap.exists) {
        final data = snap.data();
        final existing = data?['referralCode'] as String?;
        if (existing != null && existing.isNotEmpty) return;
      }

      // Generate deterministic short code based on uid
      final code = _generateReferralCode(user.uid);

      await docRef.set({'referralCode': code}, SetOptions(merge: true));
    } catch (e) {
      // ignore
    }
  }

  String _generateReferralCode(String uid) {
    // Simple base62-encode of a numeric hash of the UID to get a short code
    final hash = uid.codeUnits.fold<int>(0, (p, c) => (p * 31 + c) & 0x7fffffff);
    const alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    var val = hash == 0 ? 1 : hash;
    final buffer = StringBuffer();
    while (buffer.length < 6) {
      buffer.write(alphabet[val % alphabet.length]);
      val = val ~/ alphabet.length;
    }
    return 'CNE${buffer.toString().toUpperCase()}';
  }

  Future<void> _shareReferral() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String code = '';
      if (doc.exists) {
        code = (doc.data()?['referralCode'] as String?) ?? '';
      }
      if (code.isEmpty) {
        code = _generateReferralCode(user.uid);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'referralCode': code}, SetOptions(merge: true));
      }

      final link = 'https://coinnewsextra.app/ref?code=${Uri.encodeComponent(code)}';
      await Share.share('Join CoinNewsExtra and earn rewards! Use my referral code $code or tap: $link');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share referral: ${e.toString()}')),
      );
    }
  }

  void _loadPersistedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try Firestore first when authenticated
      String? nameFromServer;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (snap.exists) {
            final data = snap.data();
            if (data != null && data['displayName'] is String) {
              nameFromServer = (data['displayName'] as String).trim();
            }
            // Persist server values to prefs for offline use
            if (data != null && data['displayName'] is String) {
              await prefs.setString('profile_name', data['displayName'] as String);
            }
            if (data != null && data['username'] is String) {
              await prefs.setString('profile_username', data['username'] as String);
            }
          }
        }
      } catch (_) {
        // ignore Firestore errors and fall back to prefs
      }

      final saved = prefs.getString('profile_name');
      if (nameFromServer != null && nameFromServer.isNotEmpty) {
        setState(() {
          _displayName = nameFromServer;
        });
      } else if (saved != null && saved.isNotEmpty) {
        setState(() {
          _displayName = saved;
        });
      } else {
        setState(() {
          _displayName = currentUser?.displayName;
        });
      }
    } catch (e) {
      setState(() {
        _displayName = currentUser?.displayName;
      });
    }
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

  void _showWatchHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Watch History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Lato'),
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
                  final item = watchHistory[index];
                  final VideoModel video = item['video'];
                  
                  return ListTile(
                    leading: Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          'https://img.youtube.com/vi/${video.youtubeId}/mqdefault.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.play_arrow, color: Colors.white);
                          },
                        ),
                      ),
                    ),
                    title: Text(
                      video.title,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Lato'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatWatchDate(item['watchedAt']),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontFamily: 'Lato'),
                    ),
                    trailing: Text(
                      _formatDuration(video.durationSeconds ?? 0),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontFamily: 'Lato'),
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

  void _showLikedVideos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Liked Videos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Lato'),
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
                  final item = likedVideos[index];
                  final VideoModel video = item['video'];
                  
                  return ListTile(
                    leading: Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              'https://img.youtube.com/vi/${video.youtubeId}/mqdefault.jpg',
                              fit: BoxFit.cover,
                              width: 60,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.play_arrow, color: Colors.white),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      video.title,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Lato'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatWatchDate(item['likedAt']),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontFamily: 'Lato'),
                    ),
                    trailing: const Icon(
                      Icons.favorite,
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

  void _showEarningsHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Earnings History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Lato'),
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
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Lato'),
                    ),
                    subtitle: Text(
                      _formatWatchDate(transaction['timestamp']),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontFamily: 'Lato'),
                    ),
                    trailing: Text(
                      '${isPositive ? '+' : ''}${(transaction['amount'] ?? 0.0).toStringAsFixed(2)} CNE',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
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

  Future<List<Map<String, dynamic>>> _getWatchHistory() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get real videos from video data and simulate watch history
    final allVideos = VideoData.getAllVideos();
    final watchHistory = <Map<String, dynamic>>[];
    
    // Add some recent videos as watched with random timing
    if (allVideos.isNotEmpty) {
      watchHistory.add({
        'video': allVideos[0],
        'watchedAt': DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      });
    }
    if (allVideos.length > 1) {
      watchHistory.add({
        'video': allVideos[1],
        'watchedAt': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      });
    }
    if (allVideos.length > 2) {
      watchHistory.add({
        'video': allVideos[2],
        'watchedAt': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
      });
    }
    
    return watchHistory;
  }

  Future<List<Map<String, dynamic>>> _getLikedVideos() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get real videos from video data and simulate liked videos
    final allVideos = VideoData.getAllVideos();
    final likedVideos = <Map<String, dynamic>>[];
    
    // Add some videos as liked with random timing
    if (allVideos.length > 3) {
      likedVideos.add({
        'video': allVideos[3],
        'likedAt': DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
      });
    }
    if (allVideos.length > 4) {
      likedVideos.add({
        'video': allVideos[4],
        'likedAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
      });
    }
    
    return likedVideos;
  }

  Future<List<Map<String, dynamic>>> _getEarningsHistory() async {
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
        'source': 'Quiz Reward',
        'amount': 25.0,
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      },
      {
        'source': 'Spin Game',
        'amount': 15.0,
        'timestamp': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
      },
    ];
  }

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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // compute avatar initial and displayed name
    final String avatarInitial = (_displayName != null && _displayName!.isNotEmpty)
        ? _displayName![0].toUpperCase()
        : (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty)
            ? currentUser!.displayName![0].toUpperCase()
            : (currentUser?.email != null && currentUser!.email!.isNotEmpty)
                ? currentUser!.email![0].toUpperCase()
                : 'U';

    final String displayedNameLocal = _displayName ?? currentUser?.displayName ?? 'Anonymous User';

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
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
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
                            avatarInitial,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 32,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    displayedNameLocal,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email
                  Text(
                    currentUser?.email ?? 'No email',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _shareReferral,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Referral'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006833),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats Row
                  Consumer<UserBalanceService>(
                    builder: (context, balanceService, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Videos Watched', '12'),
                          Container(width: 1, height: 40, color: Colors.grey[700]),
                          _buildStatItem('Rewards Earned', '${(balanceService.balance * 0.5).toStringAsFixed(2)} CNE'),
                          Container(width: 1, height: 40, color: Colors.grey[700]),
                          _buildStatItem('Streak Days', '5'),
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
                            fontFamily: 'Lato',
                          ),
                        ),
                        Consumer<UserBalanceService>(
                          builder: (context, balanceService, child) {
                            return Text(
                              '${balanceService.getFormattedBalance()} CNE',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                fontFamily: 'Lato',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/wallet');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006833),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Wallet', style: TextStyle(fontFamily: 'Lato')),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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
              subtitle: 'Videos you have liked',
              onTap: () => _showLikedVideos(),
            ),
            _buildMenuOption(
              icon: Icons.money_outlined,
              title: 'Earnings History',
              subtitle: 'Track your rewards and earnings',
              onTap: () => _showEarningsHistory(),
            ),
            // Admin Dashboard - Only visible to admins
            Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                if (!adminProvider.isAdmin) return const SizedBox.shrink();
                
                return _buildMenuOption(
                  icon: FeatherIcons.shield,
                  title: 'Admin Dashboard',
                  subtitle: 'Manage app content and settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoleBasedAdminDashboard(),
                      ),
                    );
                  },
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.mail_outline,
              title: 'Contact Us',
              subtitle: 'Get in touch with our team',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactScreen(),
                  ),
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
                      style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
                    ),
                    content: const Text(
                      'CoinNewsExtra TV v2.0.0\n\nWatch cryptocurrency and blockchain content while earning CNE rewards.',
                      style: TextStyle(color: Colors.white70, fontFamily: 'Lato'),
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
                    fontFamily: 'Lato',
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
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontFamily: 'Lato',
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
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
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.grey[900],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}
