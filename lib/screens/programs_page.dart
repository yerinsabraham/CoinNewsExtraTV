import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import '../provider/admin_provider.dart';

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  // Demo program schedule data
  final Map<String, List<ProgramSchedule>> scheduleData = {
    'Today': [
      ProgramSchedule(
        time: '08:00 AM',
        title: 'Crypto Morning Brief',
        description: 'Daily market updates and analysis of top cryptocurrencies',
        duration: '30 min',
        category: 'News',
        isLive: false,
        thumbnail: 'assets/images/crypto_morning.jpg',
      ),
      ProgramSchedule(
        time: '09:00 AM',
        title: 'Bitcoin Deep Dive',
        description: 'Technical analysis and price predictions for Bitcoin',
        duration: '45 min',
        category: 'Analysis',
        isLive: false,
        thumbnail: 'assets/images/bitcoin_dive.jpg',
      ),
      ProgramSchedule(
        time: '10:30 AM',
        title: 'DeFi Weekly Roundup',
        description: 'Latest developments in decentralized finance protocols',
        duration: '60 min',
        category: 'DeFi',
        isLive: true,
        thumbnail: 'assets/images/defi_roundup.jpg',
      ),
      ProgramSchedule(
        time: '12:00 PM',
        title: 'Crypto Lunch Hour',
        description: 'Casual discussion about crypto trends and community updates',
        duration: '30 min',
        category: 'Discussion',
        isLive: false,
        thumbnail: 'assets/images/lunch_hour.jpg',
      ),
      ProgramSchedule(
        time: '02:00 PM',
        title: 'NFT Market Update',
        description: 'Latest trends and collections in the NFT space',
        duration: '45 min',
        category: 'NFT',
        isLive: false,
        thumbnail: 'assets/images/nft_update.jpg',
      ),
      ProgramSchedule(
        time: '04:00 PM',
        title: 'Trading Masterclass',
        description: 'Advanced trading strategies and risk management',
        duration: '90 min',
        category: 'Trading',
        isLive: false,
        thumbnail: 'assets/images/trading_class.jpg',
      ),
      ProgramSchedule(
        time: '06:30 PM',
        title: 'Blockchain Technology Explained',
        description: 'Understanding the fundamentals of blockchain technology',
        duration: '60 min',
        category: 'Education',
        isLive: false,
        thumbnail: 'assets/images/blockchain_tech.jpg',
      ),
      ProgramSchedule(
        time: '08:00 PM',
        title: 'Crypto Evening News',
        description: 'Evening wrap-up of crypto market and regulatory news',
        duration: '30 min',
        category: 'News',
        isLive: false,
        thumbnail: 'assets/images/evening_news.jpg',
      ),
    ],
    'Tomorrow': [
      ProgramSchedule(
        time: '08:00 AM',
        title: 'Market Outlook',
        description: 'Weekly crypto market analysis and upcoming events',
        duration: '45 min',
        category: 'Analysis',
        isLive: false,
        thumbnail: 'assets/images/market_outlook.jpg',
      ),
      ProgramSchedule(
        time: '09:30 AM',
        title: 'Altcoin Spotlight',
        description: 'Featured analysis of promising alternative cryptocurrencies',
        duration: '60 min',
        category: 'Analysis',
        isLive: false,
        thumbnail: 'assets/images/altcoin_spot.jpg',
      ),
      ProgramSchedule(
        time: '11:00 AM',
        title: 'Regulatory Updates',
        description: 'Latest cryptocurrency regulations and compliance news',
        duration: '30 min',
        category: 'Regulation',
        isLive: false,
        thumbnail: 'assets/images/regulations.jpg',
      ),
      ProgramSchedule(
        time: '01:00 PM',
        title: 'Community Q&A',
        description: 'Live Q&A session with crypto experts and community',
        duration: '60 min',
        category: 'Discussion',
        isLive: false,
        thumbnail: 'assets/images/qa_session.jpg',
      ),
      ProgramSchedule(
        time: '03:00 PM',
        title: 'Metaverse Insights',
        description: 'Exploring virtual worlds and metaverse investments',
        duration: '45 min',
        category: 'Metaverse',
        isLive: false,
        thumbnail: 'assets/images/metaverse.jpg',
      ),
      ProgramSchedule(
        time: '05:00 PM',
        title: 'Crypto Security 101',
        description: 'Essential security practices for crypto investors',
        duration: '60 min',
        category: 'Security',
        isLive: false,
        thumbnail: 'assets/images/security.jpg',
      ),
      ProgramSchedule(
        time: '07:00 PM',
        title: 'Web3 Innovations',
        description: 'Latest developments in Web3 technologies and dApps',
        duration: '75 min',
        category: 'Web3',
        isLive: false,
        thumbnail: 'assets/images/web3_innov.jpg',
      ),
      ProgramSchedule(
        time: '09:00 PM',
        title: 'Crypto Weekend Wrap',
        description: 'Summary of the week in cryptocurrency markets',
        duration: '30 min',
        category: 'News',
        isLive: false,
        thumbnail: 'assets/images/weekend_wrap.jpg',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
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
                const Text(
                  'Program Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAdminMenuItem(
                  icon: FeatherIcons.plus,
                  title: 'Add New Program',
                  subtitle: 'Schedule a new TV program',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Add Program');
                  },
                ),
                _buildAdminMenuItem(
                  icon: FeatherIcons.edit,
                  title: 'Edit Programs',
                  subtitle: 'Modify existing program schedules',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Edit Programs');
                  },
                ),
                _buildAdminMenuItem(
                  icon: FeatherIcons.trash2,
                  title: 'Remove Programs',
                  subtitle: 'Delete programs from schedule',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Remove Programs');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF006833),
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: const Color(0xFF006833).withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF006833),
        behavior: SnackBarBehavior.floating,
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
          'TV Programs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF006833),
          labelColor: const Color(0xFF006833),
          unselectedLabelColor: Colors.grey[400],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Tomorrow'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleList('Today'),
          _buildScheduleList('Tomorrow'),
        ],
      ),
      floatingActionButton: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (!adminProvider.isAdmin || adminProvider.isLoading) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: () => _showAdminMenu(context),
            backgroundColor: const Color(0xFF006833),
            foregroundColor: Colors.white,
            child: const Icon(FeatherIcons.plus),
          );
        },
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

  Widget _buildProgramCard(ProgramSchedule program) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: program.isLive 
          ? Border.all(color: Colors.red, width: 2)
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program header with time and live status
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006833),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    program.time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(program.category),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    program.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                if (program.isLive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
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
                        const SizedBox(width: 4),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  program.duration,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          
          // Program content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  program.description,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.4,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    if (program.isLive)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _watchLive(program),
                          icon: const Icon(FeatherIcons.play, size: 16),
                          label: const Text('Watch Live'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _setReminder(program),
                          icon: const Icon(FeatherIcons.bell, size: 16),
                          label: const Text('Set Reminder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006833),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _shareProgram(program),
                      icon: const Icon(FeatherIcons.share2, size: 16),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
      default:
        return Colors.grey;
    }
  }

  void _watchLive(ProgramSchedule program) {
    Navigator.pushNamed(context, '/live-tv');
  }

  void _setReminder(ProgramSchedule program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Reminder Set',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'You will be notified 15 minutes before "${program.title}" starts at ${program.time}.',
          style: TextStyle(color: Colors.grey[300], fontFamily: 'Lato'),
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

  void _shareProgram(ProgramSchedule program) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${program.title}"...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class ProgramSchedule {
  final String time;
  final String title;
  final String description;
  final String duration;
  final String category;
  final bool isLive;
  final String thumbnail;

  ProgramSchedule({
    required this.time,
    required this.title,
    required this.description,
    required this.duration,
    required this.category,
    this.isLive = false,
    required this.thumbnail,
  });
}
