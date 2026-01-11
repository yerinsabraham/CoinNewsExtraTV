import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_settings_page.dart';
import '../services/notification_service.dart';
import '../widgets/ads_carousel.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  // schedule capture/export removed to avoid PDF/download and storage permission issues
  final Set<String> _reminderKeys = <String>{};
  final Map<String, bool> _isSettingReminder = {};

  // TV schedule data for crypto programs
  final Map<String, List<TVProgram>> scheduleData = {
    'Today': [
      TVProgram(
        time: '08:00 AM',
        title: 'Crypto Morning Brief',
        description:
            'Start your day with the latest cryptocurrency market updates, breaking news, and analysis of top digital assets.',
        duration: '30 min',
        category: 'News',
        isLive: false,
        thumbnail: 'assets/images/summit1.png',
        host: 'Sarah Chen',
        viewers: '12.5K',
      ),
      TVProgram(
        time: '09:00 AM',
        title: 'Bitcoin Deep Dive',
        description:
            'Comprehensive technical analysis and price predictions for Bitcoin with expert traders and analysts.',
        duration: '45 min',
        category: 'Analysis',
        isLive: false,
        thumbnail: 'assets/images/summit2.png',
        host: 'Michael Rodriguez',
        viewers: '18.2K',
      ),
      TVProgram(
        time: '12:00 PM',
        title: 'Crypto Lunch & Learn',
        description:
            'Casual discussion about crypto trends, community updates, and educational content for beginners.',
        duration: '30 min',
        category: 'Education',
        isLive: false,
        thumbnail: 'assets/images/summit3.png',
        host: 'Emma Wilson',
        viewers: '9.8K',
      ),
      TVProgram(
        time: '02:00 PM',
        title: 'NFT Market Spotlight',
        description:
            'Latest trends, featured collections, and artist interviews in the dynamic NFT marketplace.',
        duration: '45 min',
        category: 'NFT',
        isLive: false,
        thumbnail: 'assets/images/summit4.png',
        host: 'David Kim',
        viewers: '14.3K',
      ),
      TVProgram(
        time: '04:00 PM',
        title: 'Trading Masterclass',
        description:
            'Advanced trading strategies, risk management, and portfolio optimization with professional traders.',
        duration: '90 min',
        category: 'Trading',
        isLive: false,
        thumbnail: 'assets/images/summit1.png',
        host: 'Jennifer Martinez',
        viewers: '32.1K',
      ),
      TVProgram(
        time: '06:30 PM',
        title: 'Blockchain Tech Explained',
        description:
            'Understanding the fundamentals of blockchain technology, consensus mechanisms, and emerging innovations.',
        duration: '60 min',
        category: 'Technology',
        isLive: false,
        thumbnail: 'assets/images/summit2.png',
        host: 'Robert Chang',
        viewers: '16.9K',
      ),
      TVProgram(
        time: '08:00 PM',
        title: 'Crypto Evening Wrap',
        description:
            'Evening summary of crypto market movements, regulatory news, and tomorrow\'s outlook.',
        duration: '30 min',
        category: 'News',
        isLive: false,
        thumbnail: 'assets/images/summit3.png',
        host: 'Lisa Parker',
        viewers: '21.4K',
      ),
    ],
    'Tomorrow': [
      TVProgram(
        time: '08:00 AM',
        title: 'Weekly Market Outlook',
        description:
            'Comprehensive weekly crypto market analysis, upcoming events, and key levels to watch.',
        duration: '45 min',
        category: 'Analysis',
        isLive: false,
        thumbnail: 'assets/images/summit1.png',
        host: 'Mark Johnson',
        viewers: '0',
      ),
      TVProgram(
        time: '09:30 AM',
        title: 'Altcoin Discovery',
        description:
            'Featured analysis of promising alternative cryptocurrencies and emerging blockchain projects.',
        duration: '60 min',
        category: 'Analysis',
        isLive: false,
        thumbnail: 'assets/images/summit2.png',
        host: 'Rachel Green',
        viewers: '0',
      ),
      TVProgram(
        time: '11:00 AM',
        title: 'Regulatory Watch',
        description:
            'Latest cryptocurrency regulations, compliance updates, and policy impacts across global markets.',
        duration: '30 min',
        category: 'Regulation',
        isLive: false,
        thumbnail: 'assets/images/summit3.png',
        host: 'Thomas Anderson',
        viewers: '0',
      ),
      TVProgram(
        time: '01:00 PM',
        title: 'Community Q&A Live',
        description:
            'Interactive Q&A session with crypto experts, answering viewer questions and market concerns.',
        duration: '60 min',
        category: 'Discussion',
        isLive: false,
        thumbnail: 'assets/images/summit4.png',
        host: 'Monica Davis',
        viewers: '0',
      ),
      TVProgram(
        time: '03:00 PM',
        title: 'Metaverse & Gaming',
        description:
            'Exploring virtual worlds, gaming tokens, and metaverse investment opportunities.',
        duration: '45 min',
        category: 'Metaverse',
        isLive: false,
        thumbnail: 'assets/images/summit1.png',
        host: 'Carlos Rivera',
        viewers: '0',
      ),
      TVProgram(
        time: '05:00 PM',
        title: 'Crypto Security Deep Dive',
        description:
            'Essential security practices, wallet safety, and protecting your crypto investments.',
        duration: '60 min',
        category: 'Security',
        isLive: false,
        thumbnail: 'assets/images/summit2.png',
        host: 'Amanda Foster',
        viewers: '0',
      ),
      TVProgram(
        time: '07:00 PM',
        title: 'Web3 Innovation Hub',
        description:
            'Latest developments in Web3 technologies, dApps, and decentralized internet infrastructure.',
        duration: '75 min',
        category: 'Web3',
        isLive: false,
        thumbnail: 'assets/images/summit3.png',
        host: 'Kevin Liu',
        viewers: '0',
      ),
      TVProgram(
        time: '09:00 PM',
        title: 'Weekend Crypto Recap',
        description:
            'Comprehensive summary of the week in cryptocurrency markets and key developments.',
        duration: '30 min',
        category: 'News',
        isLive: false,
        thumbnail: 'assets/images/summit4.png',
        host: 'Stephanie Brown',
        viewers: '0',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPersistedReminders();
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
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false),
        ),
        title: const Text(
          'TV Programs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.calendar, color: Colors.white),
            onPressed: () async {
              await _downloadSchedule();
            },
          ),
          IconButton(
            icon: const Icon(FeatherIcons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => const NotificationSettingsPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF006833),
          labelColor: const Color(0xFF006833),
          unselectedLabelColor: Colors.grey[400],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Tomorrow'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Ads carousel
          const AdsCarousel(),

          // Tab view content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleList('Today'),
                _buildScheduleList('Tomorrow'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(String day) {
    final programs = scheduleData[day] ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        return _buildProgramCard(program);
      },
    );
  }

  Widget _buildProgramCard(TVProgram program) {
    final isToday = _tabController.index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: program.isLive
            ? Border.all(color: Colors.red, width: 2)
            : Border.all(color: Colors.grey[800]!, width: 1),
        boxShadow: program.isLive
            ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006833).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Time badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006833),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    program.time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Program thumbnail
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006833).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF006833).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: program.thumbnail != null
                        ? Image.asset(
                            program.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.tv,
                              color: Color(0xFF006833),
                              size: 24,
                            ),
                          )
                        : const Icon(
                            Icons.tv,
                            color: Color(0xFF006833),
                            size: 24,
                          ),
                  ),
                ),

                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(program.category),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    program.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),

                // Live indicator
                if (program.isLive) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Duration and viewers
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      program.duration,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                      ),
                    ),
                    if (isToday && program.viewers != '0')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FeatherIcons.eye,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              program.viewers,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Program content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  program.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),

                const SizedBox(height: 8),

                // Host info
                Row(
                  children: [
                    Icon(
                      FeatherIcons.user,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hosted by ${program.host}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  program.description,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'Lato',
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Builder(builder: (context) {
                      final key = _reminderKeyFor(program);
                      final isSetting = _isSettingReminder[key] ?? false;
                      final isReminderSet = _reminderKeys.contains(key);

                      if (program.isLive) {
                        return Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _watchLive(program),
                            icon: const Icon(FeatherIcons.play, size: 18),
                            label: Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'Watch Live',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        );
                      }

                      return Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isSetting || isReminderSet
                              ? null
                              : () => _setReminder(program),
                          icon: isSetting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(FeatherIcons.bell, size: 18),
                          label: Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  isReminderSet
                                      ? 'Reminder Set'
                                      : 'Set Reminder',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReminderSet
                                ? Colors.amber
                                : const Color(0xFF006833),
                            foregroundColor:
                                isReminderSet ? Colors.black : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => _shareProgram(program),
                        icon: const Icon(
                          FeatherIcons.share2,
                          size: 18,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'news':
        return Colors.blue;
      case 'analysis':
        return Colors.purple;
      case 'defi':
        return Colors.green;
      case 'nft':
        return Colors.pink;
      case 'trading':
        return Colors.orange;
      case 'education':
        return Colors.teal;
      case 'discussion':
        return Colors.indigo;
      case 'regulation':
        return Colors.red;
      case 'metaverse':
        return Colors.cyan;
      case 'security':
        return Colors.amber;
      case 'web3':
        return Colors.deepPurple;
      case 'technology':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _downloadSchedule() async {
    // Fallback 'download' that copies a plain-text schedule to clipboard.
    final buffer = StringBuffer();
    buffer.writeln('CoinNewsExtra TV - Schedule');
    buffer.writeln('');
    for (final day in scheduleData.keys) {
      buffer.writeln('--- $day ---');
      for (final p in scheduleData[day]!) {
        buffer.writeln('${p.time} - ${p.title} (${p.duration})');
      }
      buffer.writeln('');
    }

    final text = buffer.toString();
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule copied to clipboard')));
  }

  void _watchLive(TVProgram program) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening live stream for "${program.title}"...'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Watch',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to live TV or video player
            Navigator.pushNamed(context, '/live-tv');
          },
        ),
      ),
    );
  }

  String _reminderKeyFor(TVProgram p) =>
      'program_reminder_${p.time}_${p.title}';

  Future<void> _loadPersistedReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    setState(() {
      _reminderKeys.clear();
      for (final k in keys) {
        if (k.startsWith('program_reminder_')) _reminderKeys.add(k);
      }
    });
  }

  Future<void> _setReminder(TVProgram program) async {
    // Parse program.time (assumed in format 'HH:MM AM/PM') and compute scheduled datetime for today/tomorrow
    DateTime now = DateTime.now();
    try {
      final parts = program.time.split(' ');
      final timePart = parts[0]; // '08:00'
      final ampm = parts.length > 1 ? parts[1] : 'AM';
      final hm = timePart.split(':');
      int hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      if (ampm.toUpperCase() == 'PM' && hour < 12) hour += 12;
      if (ampm.toUpperCase() == 'AM' && hour == 12) hour = 0;

      DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        // schedule for tomorrow
        scheduled = scheduled.add(const Duration(days: 1));
      }

      // notify 15 minutes before
      final scheduledNotif = scheduled.subtract(const Duration(minutes: 15));

      // Check user preference
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('program_reminders_enabled') ?? true;
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Program reminders are disabled in settings')));
        return;
      }

      final key = _reminderKeyFor(program);

      setState(() {
        _isSettingReminder[key] = true;
      });

      final id = await NotificationService().scheduleNotificationForDate(
        title: 'Upcoming: ${program.title}',
        body: '${program.title} starts at ${program.time}',
        scheduledDate: scheduledNotif,
      );

      // Persist a simple flag so UI can reflect reminder set and store id for cancellation
      await prefs.setBool(key, true);
      await prefs.setInt('${key}_id', id);

      setState(() {
        _isSettingReminder.remove(key);
        _reminderKeys.add(key);
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder set for ${program.title}')));
    } catch (e) {
      debugPrint('❌ Error scheduling reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to set reminder')));
    }
  }

  void _shareProgram(TVProgram program) {
    // Copy a program-specific link to clipboard (no descriptive text)
    final encodedTitle = Uri.encodeComponent(program.title);
    final encodedTime = Uri.encodeComponent(program.time);
    final link =
        'https://coinnewsextra.com/programs?title=$encodedTitle&time=$encodedTime';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Program link copied to clipboard.')),
    );
    return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share "${program.title}"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(FeatherIcons.copy, 'Copy Link'),
                _buildShareOption(FeatherIcons.messageCircle, 'Message'),
                _buildShareOption(FeatherIcons.mail, 'Email'),
                _buildShareOption(FeatherIcons.moreHorizontal, 'More'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label functionality coming soon!'),
            backgroundColor: const Color(0xFF006833),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF006833).withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF006833),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(FeatherIcons.calendar, color: Color(0xFF006833), size: 24),
            SizedBox(width: 12),
            Text(
              'Schedule Options',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 'Download Schedule' feature intentionally removed to avoid file export and storage permission changes.
            ListTile(
              leading:
                  const Icon(FeatherIcons.settings, color: Color(0xFF006833)),
              title: const Text(
                'Notification Settings',
                style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => const NotificationSettingsPage()),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF006833),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TVProgram {
  final String time;
  final String title;
  final String description;
  final String duration;
  final String category;
  final bool isLive;
  final String host;
  final String viewers;

  TVProgram({
    required this.time,
    required this.title,
    required this.description,
    required this.duration,
    required this.category,
    this.isLive = false,
    this.thumbnail,
    required this.host,
    required this.viewers,
  });

  final String? thumbnail;
}
