import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
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
  
  final bool _isOnline = true;
  final int _onlineUsers = 42; // Mock count, would be real in production
  String _currentUserName = '';
  bool _showEmojiPicker = false;

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
    
    // Listen to text changes for send button state
    _messageController.addListener(() {
      setState(() {});
    });
    
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
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to send messages'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    print('Sending message: $messageText'); // Debug
    
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      username: _currentUserName.isNotEmpty ? _currentUserName : 'User',
      message: messageText,
      timestamp: DateTime.now(),
    );

    try {
      // Clear the message immediately for better UX
      _messageController.clear();
      setState(() {}); // Update UI
      
      // Save to Firestore
      await _firestore.collection('chat_messages').add(message.toFirestore());
      
      // Auto-scroll to bottom after message is added
      Future.delayed(const Duration(milliseconds: 500), () {
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
            duration: Duration(seconds: 1),
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
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: isCurrentUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser && !message.isSystem)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar circle
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF006833),
                          Color(0xFF00A651),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        message.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.username,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isSystem
                  ? const Color(0xFF006833).withOpacity(0.15)
                  : isCurrentUser
                      ? null
                      : Colors.grey[850],
              gradient: isCurrentUser && !message.isSystem
                  ? const LinearGradient(
                      colors: [Color(0xFF006833), Color(0xFF00A651)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isCurrentUser ? 20 : 6),
                bottomRight: Radius.circular(isCurrentUser ? 6 : 20),
              ),
              border: message.isSystem
                  ? Border.all(color: const Color(0xFF006833).withOpacity(0.5), width: 1)
                  : null,
              boxShadow: !message.isSystem ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isSystem)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF006833),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CoinNews Extra',
                        style: TextStyle(
                          color: Color(0xFF006833),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (message.isSystem) const SizedBox(height: 6),
                Text(
                  message.message,
                  style: TextStyle(
                    color: message.isSystem 
                        ? Colors.white
                        : Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isCurrentUser ? 0 : 16,
              right: isCurrentUser ? 16 : 0,
              top: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    color: Colors.grey[600],
                    size: 12,
                  ),
                ],
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
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Chat icon with gradient background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006833), Color(0xFF00A651)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.forum,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Community Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _connectionAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _isOnline 
                                  ? const Color(0xFF00A651).withOpacity(_connectionAnimation.value)
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_onlineUsers online',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800]?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF006833), Color(0xFF00A651)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Chat Guidelines',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    '• Be respectful to all members 🤝\n'
                    '• No spam or excessive messaging 🚫\n'
                    '• Crypto discussion encouraged 💰\n'
                    '• Earn 0.1 CNE per message 🎁\n'
                    '• Have fun and learn together! 🚀',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF006833),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(
                          'Got it!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
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
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chat_messages')
                    .orderBy('timestamp', descending: false)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading messages',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
                      ),
                    );
                  }

                  final messages = snapshot.data?.docs ?? [];
                  
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageDoc = messages[index];
                      final message = ChatMessage.fromFirestore(messageDoc);
                      final isCurrentUser = message.userId == _auth.currentUser?.uid;
                      
                      return _buildMessageBubble(message, isCurrentUser);
                    },
                  );
                },
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
                    icon: Icon(
                      _showEmojiPicker 
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                      color: _showEmojiPicker 
                          ? const Color(0xFF006833)
                          : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      });
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
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() {
                              _showEmojiPicker = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send button - Enhanced with better visual feedback
                  GestureDetector(
                    onTap: () {
                      print('Send button tapped!'); // Debug
                      print('Message text: "${_messageController.text}"'); // Debug
                      
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty) {
                        _sendMessage();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a message first'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF006833), // Always active for testing
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
          
          // Emoji Picker
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                textEditingController: _messageController,
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: Colors.grey[900]!,
                    columns: 7,
                    emojiSizeMax: 28.0,
                    recentsLimit: 28,
                    replaceEmojiOnLimitExceed: false,
                    noRecents: const Text(
                      'No recent emojis',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    loadingIndicator: const SizedBox.shrink(),

                    buttonMode: ButtonMode.MATERIAL,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    backgroundColor: Color(0xFF2C2C2C),
                    buttonColor: Colors.grey,
                    buttonIconColor: Colors.white,
                    showSearchViewButton: true,
                  ),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: Colors.grey[900]!,
                    buttonIconColor: Colors.white,
                    hintText: 'Search emoji...',
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    initCategory: Category.RECENT,
                    backgroundColor: Color(0xFF2C2C2C),
                    indicatorColor: Color(0xFF006833),
                    iconColorSelected: Color(0xFF006833),
                    iconColor: Colors.grey,
                    tabBarHeight: 46,
                    dividerColor: Colors.grey,
                    categoryIcons: CategoryIcons(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}