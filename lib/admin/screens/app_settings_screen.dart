import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // App Preferences
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _darkMode = true;
  bool _autoPlay = false;
  String _defaultLanguage = 'English';
  String _defaultCurrency = 'USD';

  // System Options
  bool _maintenanceMode = false;
  bool _registrationOpen = true;
  bool _debugMode = false;
  String _maxUsers = '10000';
  String _sessionTimeout = '30';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          'App Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.save, color: Colors.white),
            onPressed: _saveSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF006833),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold),
          isScrollable: true,
          tabs: const [
            Tab(
              child: Row(
                children: [
                  Icon(FeatherIcons.settings, size: 16),
                  SizedBox(width: 6),
                  Text('Preferences'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  Icon(FeatherIcons.server, size: 16),
                  SizedBox(width: 6),
                  Text('System'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  Icon(FeatherIcons.key, size: 16),
                  SizedBox(width: 6),
                  Text('API Keys'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  Icon(FeatherIcons.bell, size: 16),
                  SizedBox(width: 6),
                  Text('Notifications'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPreferencesTab(),
          _buildSystemTab(),
          _buildApiKeysTab(),
          _buildNotificationsTab(),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Preferences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 20),

          _buildSettingCard(
            'Dark Mode',
            'Use dark theme throughout the app',
            _darkMode,
            (value) => setState(() => _darkMode = value),
            FeatherIcons.moon,
          ),
          const SizedBox(height: 12),

          _buildSettingCard(
            'Auto-Play Videos',
            'Automatically play videos when selected',
            _autoPlay,
            (value) => setState(() => _autoPlay = value),
            FeatherIcons.play,
          ),
          const SizedBox(height: 12),

          _buildDropdownCard(
            'Default Language',
            'Primary language for the app interface',
            _defaultLanguage,
            ['English', 'Spanish', 'French', 'German', 'Chinese'],
            (value) => setState(() => _defaultLanguage = value!),
            FeatherIcons.globe,
          ),
          const SizedBox(height: 12),

          _buildDropdownCard(
            'Default Currency',
            'Default currency for rewards and payments',
            _defaultCurrency,
            ['USD', 'EUR', 'GBP', 'JPY', 'CNET'],
            (value) => setState(() => _defaultCurrency = value!),
            FeatherIcons.dollarSign,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 20),

          _buildSettingCard(
            'Maintenance Mode',
            'Temporarily disable app for maintenance',
            _maintenanceMode,
            (value) => setState(() => _maintenanceMode = value),
            FeatherIcons.tool,
          ),
          const SizedBox(height: 12),

          _buildSettingCard(
            'Registration Open',
            'Allow new users to register accounts',
            _registrationOpen,
            (value) => setState(() => _registrationOpen = value),
            FeatherIcons.userPlus,
          ),
          const SizedBox(height: 12),

          _buildSettingCard(
            'Debug Mode',
            'Enable detailed logging and debugging',
            _debugMode,
            (value) => setState(() => _debugMode = value),
            FeatherIcons.code,
          ),
          const SizedBox(height: 12),

          _buildTextFieldCard(
            'Maximum Users',
            'Maximum number of registered users',
            _maxUsers,
            (value) => setState(() => _maxUsers = value),
            FeatherIcons.users,
          ),
          const SizedBox(height: 12),

          _buildTextFieldCard(
            'Session Timeout',
            'User session timeout in minutes',
            _sessionTimeout,
            (value) => setState(() => _sessionTimeout = value),
            FeatherIcons.clock,
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeysTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API Keys & Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 20),

          _buildApiKeyCard(
            'Firebase Configuration',
            'Firebase project settings and keys',
            'Configured ✓',
            Colors.orange,
            FeatherIcons.database,
          ),
          const SizedBox(height: 12),

          _buildApiKeyCard(
            'Agora RTC Engine',
            'Voice and video calling integration',
            'Ready for Phase 3',
            Colors.blue,
            FeatherIcons.phone,
          ),
          const SizedBox(height: 12),

          _buildApiKeyCard(
            'YouTube Data API',
            'YouTube video data integration',
            'Not configured',
            Colors.red,
            FeatherIcons.youtube,
          ),
          const SizedBox(height: 12),

          _buildApiKeyCard(
            'Push Notifications',
            'Firebase Cloud Messaging keys',
            'Configured ✓',
            const Color(0xFF006833),
            FeatherIcons.bell,
          ),
          const SizedBox(height: 12),

          _buildApiKeyCard(
            'Analytics',
            'App usage and performance tracking',
            'Configured ✓',
            Colors.purple,
            FeatherIcons.barChart,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 20),

          _buildSettingCard(
            'Push Notifications',
            'Send mobile push notifications to users',
            _pushNotifications,
            (value) => setState(() => _pushNotifications = value),
            FeatherIcons.smartphone,
          ),
          const SizedBox(height: 12),

          _buildSettingCard(
            'Email Notifications',
            'Send email notifications for important updates',
            _emailNotifications,
            (value) => setState(() => _emailNotifications = value),
            FeatherIcons.mail,
          ),
          const SizedBox(height: 20),

          const Text(
            'Email Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            'SMTP Server',
            'smtp.gmail.com',
            FeatherIcons.server,
          ),
          const SizedBox(height: 8),

          _buildInfoCard(
            'From Email',
            'noreply@coinnewsextra.com',
            FeatherIcons.mail,
          ),
          const SizedBox(height: 8),

          _buildInfoCard(
            'Templates',
            'Welcome, Reset Password, Announcements',
            FeatherIcons.fileText,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, String description, bool value, Function(bool) onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF006833), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF006833),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCard(String title, String description, String value, List<String> options, Function(String?) onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF006833), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            dropdownColor: Colors.grey[800],
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Lato',
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldCard(String title, String description, String value, Function(String) onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF006833), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: TextEditingController(text: value),
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Lato',
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF006833)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyCard(String title, String description, String status, Color statusColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showApiKeyDialog(title),
            icon: Icon(FeatherIcons.settings, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 16),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[300],
              fontFamily: 'Lato',
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(String apiName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          '$apiName Configuration',
          style: const TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'API key configuration for $apiName will be implemented in Phase 3.\n\nThis will include:\n• Secure key management\n• Configuration validation\n• Connection testing\n• Usage monitoring',
          style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF006833), fontFamily: 'Lato'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // TODO: Implement actual settings persistence
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Color(0xFF006833),
      ),
    );
  }
}