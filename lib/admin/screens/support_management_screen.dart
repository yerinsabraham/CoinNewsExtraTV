import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../../help_support/services/support_service.dart';
import '../../help_support/models/support_ticket.dart';
import '../../help_support/models/support_chat.dart';
import '../../help_support/models/support_call.dart';

class SupportManagementScreen extends StatefulWidget {
  const SupportManagementScreen({super.key});

  @override
  State<SupportManagementScreen> createState() => _SupportManagementScreenState();
}

class _SupportManagementScreenState extends State<SupportManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _supportStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSupportStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSupportStats() async {
    try {
      final stats = await SupportService.getSupportStats();
      if (mounted) {
        setState(() {
          _supportStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
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
          'Support Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.refreshCw, color: Colors.white),
            onPressed: _loadSupportStats,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF006833),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FeatherIcons.fileText, size: 16),
                  const SizedBox(width: 6),
                  const Text('Tickets'),
                  if (_supportStats?['openTickets'] != null && _supportStats!['openTickets'] > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _supportStats!['openTickets'].toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FeatherIcons.messageCircle, size: 16),
                  const SizedBox(width: 6),
                  const Text('Chats'),
                  if (_supportStats?['activeChats'] != null && _supportStats!['activeChats'] > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006833),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _supportStats!['activeChats'].toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FeatherIcons.phone, size: 16),
                  const SizedBox(width: 6),
                  const Text('Calls'),
                  if (_supportStats?['pendingCalls'] != null && _supportStats!['pendingCalls'] > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _supportStats!['pendingCalls'].toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.barChart, size: 16),
                  SizedBox(width: 6),
                  Text('Stats'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketsTab(),
          _buildChatsTab(),
          _buildCallsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildTicketsTab() {
    return StreamBuilder<List<SupportTicket>>(
      stream: SupportService.getAllTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF006833)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FeatherIcons.alertCircle, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Error loading tickets',
                  style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
                ),
              ],
            ),
          );
        }

        final tickets = snapshot.data ?? [];

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FeatherIcons.inbox, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No support tickets',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return _buildTicketCard(ticket);
          },
        );
      },
    );
  }

  Widget _buildChatsTab() {
    return StreamBuilder<List<SupportChat>>(
      stream: SupportService.getAllChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF006833)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FeatherIcons.alertCircle, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Error loading chats',
                  style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
                ),
              ],
            ),
          );
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FeatherIcons.messageSquare, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No active chats',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return _buildChatCard(chat);
          },
        );
      },
    );
  }

  Widget _buildCallsTab() {
    return StreamBuilder<List<SupportCall>>(
      stream: SupportService.getPendingCalls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF006833)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FeatherIcons.alertCircle, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Error loading calls',
                  style: TextStyle(color: Colors.grey[400], fontFamily: 'Lato'),
                ),
              ],
            ),
          );
        }

        final calls = snapshot.data ?? [];

        if (calls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FeatherIcons.phoneOff, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No pending calls',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: calls.length,
          itemBuilder: (context, index) {
            final call = calls[index];
            return _buildCallCard(call);
          },
        );
      },
    );
  }

  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF006833)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 20),
          
          // Overall Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Tickets',
                  _supportStats?['totalTickets']?.toString() ?? '0',
                  FeatherIcons.fileText,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Open Tickets',
                  _supportStats?['openTickets']?.toString() ?? '0',
                  FeatherIcons.alertCircle,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Chats',
                  _supportStats?['totalChats']?.toString() ?? '0',
                  FeatherIcons.messageCircle,
                  const Color(0xFF006833),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active Chats',
                  _supportStats?['activeChats']?.toString() ?? '0',
                  FeatherIcons.users,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Calls',
                  _supportStats?['totalCalls']?.toString() ?? '0',
                  FeatherIcons.phone,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending Calls',
                  _supportStats?['pendingCalls']?.toString() ?? '0',
                  FeatherIcons.phoneIncoming,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTicketStatusColor(ticket.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: _getTicketStatusColor(ticket.status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              const Spacer(),
              Text(
                ticket.priority.toUpperCase(),
                style: TextStyle(
                  color: _getPriorityColor(ticket.priority),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'From: ${ticket.userName} (${ticket.userEmail})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ticket.issueDescription,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'Lato',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(SupportChat chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getChatStatusColor(chat.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chat.subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              if (chat.unreadByAdmin > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    chat.unreadByAdmin.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'User: ${chat.userName} (${chat.userEmail})',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'Lato',
            ),
          ),
          if (chat.lastMessage.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Last: ${chat.lastMessage}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontFamily: 'Lato',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallCard(SupportCall call) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FeatherIcons.phone,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  call.userEmail,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement call handling
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call handling coming in Phase 3!'),
                  backgroundColor: Color(0xFF006833),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006833),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Answer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTicketStatusColor(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return Colors.orange;
      case SupportTicketStatus.inProgress:
        return const Color(0xFF006833);
      case SupportTicketStatus.resolved:
        return Colors.blue;
      case SupportTicketStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getChatStatusColor(SupportChatStatus status) {
    switch (status) {
      case SupportChatStatus.active:
        return const Color(0xFF006833);
      case SupportChatStatus.waiting:
        return Colors.orange;
      case SupportChatStatus.closed:
        return Colors.grey;
    }
  }
}