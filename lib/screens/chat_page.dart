import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/user_balance_service.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String username;
  final String message;
  final DateTime timestamp;
  final bool isSystem;
  final String? avatarUrl;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.message,
    required this.timestamp,
    this.isSystem = false,
    this.avatarUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystem: data['isSystem'] ?? false,
      avatarUrl: data['avatarUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSystem': isSystem,
      'avatarUrl': avatarUrl,
    };
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late AnimationController _connectionAnimationController;
  late Animation<double> _connectionAnimation;
  
  bool _isOnline = true;
  int _onlineUsers = 42; // Mock count, would be real in production
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    
    _connectionAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _connectionAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _connectionAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _getCurrentUserName();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _connectionAnimationController.dispose();
    super.dispose();
  }

  void _getCurrentUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Try to get display name from Firestore user document
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _currentUserName = userData['displayName'] ?? 
                             userData['username'] ?? 
                             user.displayName ?? 
                             'User${user.uid.substring(0, 6)}';
          });
        } else {
          setState(() {
            _currentUserName = user.displayName ?? 'User${user.uid.substring(0, 6)}';
          });
        }
      } catch (e) {
        setState(() {
          _currentUserName = user.displayName ?? 'User${user.uid.substring(0, 6)}';
        });
      }
    }
  }

  void _addWelcomeMessage() async {
    // Add a welcome system message for new users (mock implementation)
    if (_currentUserName.isNotEmpty) {
      final welcomeMessage = ChatMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'system',
        username: 'CoinNews Extra',
        message: 'Welcome to CoinNews Extra Chat! 🚀 Discuss crypto, share insights, and earn rewards!',
        timestamp: DateTime.now(),
        isSystem: true,
      );
      
      // In a real app, this would be added to Firestore
      // await _firestore.collection('chat_messages').add(welcomeMessage.toFirestore());
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    User? user = _auth.currentUser;
    if (user == null) return;

    final message = ChatMessage(
      id: '',
      userId: user.uid,
      username: _currentUserName,
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      // In a real implementation, save to Firestore
      await _firestore.collection('chat_messages').add(message.toFirestore());
      
      _messageController.clear();
      
      // Auto-scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Award small reward for participation
      if (mounted) {
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.addBalance(0.1, 'Chat participation');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('+0.1 CNE for chat participation!'),
            backgroundColor: Color(0xFF006833),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    return Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 60 : 16,
        right: isCurrentUser ? 16 : 60,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: isCurrentUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser && !message.isSystem)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                message.username,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isSystem
                  ? const Color(0xFF006833).withOpacity(0.2)
                  : isCurrentUser
                      ? const Color(0xFF006833)
                      : Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
              border: message.isSystem
                  ? Border.all(color: const Color(0xFF006833), width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isSystem)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF006833),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'System',
                        style: TextStyle(
                          color: const Color(0xFF006833),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (message.isSystem) const SizedBox(height: 4),
                Text(
                  message.message,
                  style: TextStyle(
                    color: message.isSystem 
                        ? Colors.white
                        : isCurrentUser
                            ? Colors.white
                            : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isCurrentUser ? 0 : 12,
              right: isCurrentUser ? 12 : 0,
              top: 4,
            ),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Widget _buildMockMessages() {
    final mockMessages = [
      ChatMessage(
        id: '1',
        userId: 'system',
        username: 'CoinNews Extra',
        message: 'Welcome to CoinNews Extra Chat! 🚀 Discuss crypto, share insights, and earn rewards!',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isSystem: true,
      ),
      ChatMessage(
        id: '2',
        userId: 'user1',
        username: 'CryptoTrader',
        message: 'Bitcoin looking strong today! 📈',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      ChatMessage(
        id: '3',
        userId: 'user2',
        username: 'BlockchainPro',
        message: 'Anyone else bullish on ETH? The merge was a game changer',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        id: '4',
        userId: 'user3',
        username: 'DeFiEnthusiast',
        message: 'Just earned 5 CNE tokens from the spin wheel! 🎰',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ChatMessage(
        id: '5',
        userId: 'user4',
        username: 'AltcoinHunter',
        message: 'Love this platform! The videos are super informative 👍',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];

    return Column(
      children: mockMessages.map((message) {
        final isCurrentUser = message.userId == _auth.currentUser?.uid;
        return _buildMessageBubble(message, isCurrentUser);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _connectionAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline 
                            ? const Color(0xFF006833).withOpacity(_connectionAnimation.value)
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  '$_onlineUsers online',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Chat Rules',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    '• Be respectful to all members\n'
                    '• No spam or excessive messaging\n'
                    '• Crypto discussion encouraged\n'
                    '• Earn 0.1 CNE per message\n'
                    '• Have fun and learn together!',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(color: Color(0xFF006833)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[900]!,
                    Colors.black,
                  ],
                ),
              ),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // In a real implementation, this would be a StreamBuilder
                  // listening to Firestore chat messages
                  _buildMockMessages(),
                ],
              ),
            ),
          ),
          
          // Message input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(
                  color: Colors.grey[700]!,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Emoji button
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      // In a real app, show emoji picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emoji picker coming soon! 😊'),
                          backgroundColor: Color(0xFF006833),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF006833),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}