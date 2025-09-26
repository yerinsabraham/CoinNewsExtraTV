import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/chat_ad_carousel.dart';

class CommunityChat extends StatefulWidget {
  const CommunityChat({super.key});

  @override
  State<CommunityChat> createState() => _CommunityChatState();
}

class _CommunityChatState extends State<CommunityChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Demo chat messages with usernames
  List<ChatMessage> messages = [
    ChatMessage(
      id: '1',
      username: 'cryptowiz99',
      message: 'Hey everyone! What do you think about the recent Bitcoin pump? 🚀',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 15,
      isLikedByUser: false,
    ),
    ChatMessage(
      id: '2',
      username: 'hodler_master',
      message: 'I think we\'re just getting started. This bull run is going to be epic!',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      likes: 8,
      isLikedByUser: true,
    ),
    ChatMessage(
      id: '3',
      username: 'defi_explorer',
      message: 'Anyone else excited about the new DeFi protocols launching this month?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      likes: 12,
      isLikedByUser: false,
    ),
    ChatMessage(
      id: '4',
      username: 'blockchain_dev',
      message: 'Just deployed my first smart contract on Ethereum! The gas fees are crazy though 😅',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      likes: 23,
      isLikedByUser: true,
    ),
    ChatMessage(
      id: '5',
      username: 'nft_collector',
      message: 'The NFT market is heating up again. Found some amazing art on OpenSea!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      likes: 6,
      isLikedByUser: false,
    ),
    ChatMessage(
      id: '6',
      username: 'trader_pro',
      message: 'Technical analysis shows strong support at \$95k for BTC. What\'s your take?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      likes: 19,
      isLikedByUser: false,
    ),
    ChatMessage(
      id: '7',
      username: 'altcoin_hunter',
      message: 'Solana ecosystem is absolutely crushing it right now! 🔥',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      likes: 11,
      isLikedByUser: true,
    ),
    ChatMessage(
      id: '8',
      username: 'web3_builder',
      message: 'Building the future, one dApp at a time. Who else is developing on Web3?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      likes: 7,
      isLikedByUser: false,
    ),
  ];

  String? currentUsername;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            currentUsername = doc.data()?['username'] ?? 'user${user.uid.substring(0, 6)}';
          });
        }
      } catch (e) {
        setState(() {
          currentUsername = 'user${user.uid.substring(0, 6)}';
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF006833),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Community Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.users, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('847 members online')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Ad carousel banner at the top
          const ChatAdCarousel(),
          
          // Online users indicator
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[900],
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006833),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '847 members online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
                const Spacer(),
                Text(
                  '${messages.length} messages today',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(messages[index]);
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF006833),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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

  Widget _buildMessageItem(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF006833),
                radius: 16,
                child: Text(
                  message.username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.username,
                style: const TextStyle(
                  color: Color(0xFF006833),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleLike(message.id),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            message.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: message.isLikedByUser ? Colors.red : Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${message.likes}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _replyToMessage(message.username),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FeatherIcons.messageCircle,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ],
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _toggleLike(String messageId) {
    setState(() {
      final message = messages.firstWhere((msg) => msg.id == messageId);
      if (message.isLikedByUser) {
        message.likes--;
        message.isLikedByUser = false;
      } else {
        message.likes++;
        message.isLikedByUser = true;
      }
    });
  }

  void _replyToMessage(String username) {
    _messageController.text = '@$username ';
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || currentUsername == null) return;
    
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: currentUsername!,
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
      likes: 0,
      isLikedByUser: false,
    );
    
    setState(() {
      messages.add(newMessage);
      _messageController.clear();
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class ChatMessage {
  final String id;
  final String username;
  final String message;
  final DateTime timestamp;
  int likes;
  bool isLikedByUser;

  ChatMessage({
    required this.id,
    required this.username,
    required this.message,
    required this.timestamp,
    required this.likes,
    required this.isLikedByUser,
  });
}