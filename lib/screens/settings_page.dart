import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_balance_service.dart';
import '../services/first_launch_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _notificationsEnabled = true;
  bool _emailUpdatesEnabled = false;
  bool _autoPlayVideos = true;
  bool _darkModeEnabled = true;
  bool _isEditing = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _nameController.text = currentUser?.displayName ?? '';
    // For demo purposes, using email prefix as username
    _usernameController.text = currentUser?.email?.split('@')[0] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        // In a real app, you would upload this to Firebase Storage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated! (In demo mode)'),
            backgroundColor: Color(0xFF006833),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfileChanges() async {
    setState(() {
      _isEditing = false;
    });
    
    // In a real app, you would update Firebase Auth and Firestore here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully! (In demo mode)'),
        backgroundColor: Color(0xFF006833),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and you will lose all your data, including rewards and watch history.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion is disabled in demo mode'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfileChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF006833),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Profile Picture
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF006833),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : currentUser?.photoURL != null
                                ? NetworkImage(currentUser!.photoURL!) as ImageProvider
                                : null,
                        child: _selectedImage == null && currentUser?.photoURL == null
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
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF006833),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Profile Info
                  if (_isEditing) ...[
                    // Editable fields
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[600]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[600]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF006833)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontFamily: 'Lato',
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Enter username',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[600]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[600]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF006833)),
                        ),
                        prefixText: '@',
                        prefixStyle: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ] else ...[
                    // Display mode
                    Text(
                      _nameController.text.isNotEmpty 
                          ? _nameController.text 
                          : 'Anonymous User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${_usernameController.text}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentUser?.email ?? 'No email',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Edit Profile Button
                  if (!_isEditing)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006833),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Settings Sections
            const SizedBox(height: 24),
            
            // Notifications Section
            _buildSection(
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Receive app notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) => setState(() => _notificationsEnabled = value),
                ),
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Email Updates',
                  subtitle: 'Receive news and updates via email',
                  value: _emailUpdatesEnabled,
                  onChanged: (value) => setState(() => _emailUpdatesEnabled = value),
                ),
              ],
            ),
            
            // Privacy & Security Section
            _buildSection(
              title: 'Privacy & Security',
              children: [
                _buildMenuTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy policy would open here')),
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.security_outlined,
                  title: 'Security Settings',
                  subtitle: 'Manage your account security',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Security settings would open here')),
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.block_outlined,
                  title: 'Blocked Users',
                  subtitle: 'Manage blocked users',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Blocked users list would open here')),
                    );
                  },
                ),
              ],
            ),
            
            // App Preferences Section
            _buildSection(
              title: 'App Preferences',
              children: [
                _buildSwitchTile(
                  icon: Icons.play_arrow_outlined,
                  title: 'Auto-play Videos',
                  subtitle: 'Automatically play videos in feeds',
                  value: _autoPlayVideos,
                  onChanged: (value) => setState(() => _autoPlayVideos = value),
                ),
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme (always on in demo)',
                  value: _darkModeEnabled,
                  onChanged: (value) => setState(() => _darkModeEnabled = value),
                ),
                _buildMenuTile(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'English (US)',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language selection would open here')),
                    );
                  },
                ),
              ],
            ),
            
            // Account Management Section
            _buildSection(
              title: 'Account Management',
              children: [
                _buildMenuTile(
                  icon: Icons.download_outlined,
                  title: 'Export Data',
                  subtitle: 'Download your account data',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data export would start here')),
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  isDangerous: true,
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
            
            // Support Section
            _buildSection(
              title: 'Support',
              children: [
                _buildMenuTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'Get help and support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help center would open here')),
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.rocket_launch,
                  title: 'View Tour',
                  subtitle: 'See the app tour again',
                  onTap: () async {
                    await FirstLaunchService().requestTour();
                    // Navigate to home which will trigger the tour
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                  },
                ),
                
                _buildMenuTile(
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  subtitle: 'Share your thoughts with us',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback form would open here')),
                    );
                  },
                ),
                _buildMenuTile(
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
                          'CoinNewsExtra TV v2.0.0\n\nWatch cryptocurrency and blockchain content while earning CNE rewards.\n\n© 2024 CoinNewsExtra. All rights reserved.',
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
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF006833),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF006833),
        activeTrackColor: const Color(0xFF006833).withOpacity(0.3),
        inactiveThumbColor: Colors.grey[400],
        inactiveTrackColor: Colors.grey[700],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDangerous ? Colors.red : Colors.white,
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
        color: isDangerous ? Colors.red : Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}