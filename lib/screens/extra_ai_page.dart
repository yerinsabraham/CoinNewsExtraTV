import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker;
import '../services/user_balance_service.dart';
import '../services/openai_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isLoading;

  AIMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.isLoading = false,
  });
}

class ExtraAIPage extends StatefulWidget {
  const ExtraAIPage({super.key});

  @override
  State<ExtraAIPage> createState() => _ExtraAIPageState();
}

class _ExtraAIPageState extends State<ExtraAIPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AIMessage> _messages = [];
  final OpenAIService _openAIService = OpenAIService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Removed user-facing toggles: responses will use trusted sources and a
  // concise-but-helpful style by default (no options shown to users).
  
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  
  bool _isConnected = true;
  int _questionsAsked = 0;
  final int _dailyLimit = 10;
  bool _isProcessing = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Load persisted messages from Firestore. If none exist, show the welcome
    // message. Attempt anonymous sign-in if the user is not authenticated.
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(
      AIMessage(
        id: 'welcome',
        content: 'Hey there! 👋 I\'m ExtraAI, and I\'m excited to chat with you about all things crypto and tech!\n\n'
                'I love talking about:\n'
                '🚀 Blockchain & Cryptocurrencies\n'
                '💰 Fintech innovations\n'
                '🏥 Health Tech advances\n'
                '💻 General Technology trends\n\n'
                'Feel free to ask me anything - from "What\'s Bitcoin?" to "How are you today?" I\'m here to have a real conversation! 😊',
        isFromUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isProcessing) return;
    
    if (_questionsAsked >= _dailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily question limit reached. Try again tomorrow!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userMessage = _messageController.text.trim();
    final userAIMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userAIMessage);
      _questionsAsked++;
      _isProcessing = true;
    });

  // Persist the user message to Firestore (best-effort)
  _saveMessageToFirestore(userAIMessage);

    _messageController.clear();
    
    // Add loading message
    final loadingMessage = AIMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      content: 'Thinking...',
      isFromUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    
    setState(() {
      _messages.add(loadingMessage);
    });

    _scrollToBottom();

    try {
      // If an API key is configured, use the OpenAIService. Otherwise fall back to local generator.
      String aiResponse;
      try {
        // Use OpenAIService defaults: trusted sources are included and replies
        // are concise-but-helpful. No user-facing toggles/options are shown.
        aiResponse = await _openAIService.sendMessage(userMessage);
      } catch (_) {
        aiResponse = await _generateAIResponse(userMessage);
      }
      
      final assistantMessage = AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.removeLast(); // Remove loading message
        _messages.add(assistantMessage);
      });

  // Persist assistant reply
  _saveMessageToFirestore(assistantMessage);

      // Award tokens for AI interaction
      if (mounted) {
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.addBalance(0.5, 'AI consultation');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('+0.5 CNE for AI consultation!'),
            backgroundColor: Color(0xFF006833),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _messages.removeLast(); // Remove loading message
        _messages.add(AIMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Oops! Something went wrong on my end. 😅 Let me try to help you again - could you repeat your question? I\'m here and ready to chat!',
          isFromUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }

    _scrollToBottom();
  }

  // Load messages from Firestore for the current user. Falls back to a
  // welcome message if none are found. Counts today's user messages to set
  // the daily question usage counter.
  Future<void> _loadMessages() async {
    try {
      var user = _auth.currentUser;
      if (user == null) {
        final cred = await _auth.signInAnonymously();
        user = cred.user;
      }

      if (user == null) return;

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_messages')
          .orderBy('timestamp', descending: false)
          .get();

      final loaded = <AIMessage>[];
      for (final doc in query.docs) {
        final data = doc.data();
        final ts = data['timestamp'];
        DateTime when;
        if (ts is Timestamp) {
          when = ts.toDate();
        } else {
          when = DateTime.now();
        }

        loaded.add(AIMessage(
          id: doc.id,
          content: (data['content'] ?? '').toString(),
          isFromUser: (data['isFromUser'] ?? false) as bool,
          timestamp: when,
        ));
      }

      setState(() {
        _messages.clear();
        _messages.addAll(loaded);
        // Compute today's user-sent messages for daily limit tracking
        final today = DateTime.now();
        _questionsAsked = _messages.where((m) {
          return m.isFromUser &&
              m.timestamp.year == today.year &&
              m.timestamp.month == today.month &&
              m.timestamp.day == today.day;
        }).length;
      });

      if (_messages.isEmpty) {
        setState(() {
          _addWelcomeMessage();
        });
      }
    } catch (e) {
      debugPrint('Failed to load AI messages: $e');
      // Show welcome message if loading fails
      if (_messages.isEmpty) _addWelcomeMessage();
    }
  }

  // Save a single message to Firestore under users/{uid}/ai_messages/{id}
  Future<void> _saveMessageToFirestore(AIMessage message) async {
    try {
      var user = _auth.currentUser;
      if (user == null) {
        final cred = await _auth.signInAnonymously();
        user = cred.user;
      }
      if (user == null) return;

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_messages')
          .doc(message.id);

      await docRef.set({
        'content': message.content,
        'isFromUser': message.isFromUser,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving AI message: $e');
    }
  }

  // Clear all persisted messages for the current user (cloud + UI)
  Future<void> _clearMessages() async {
    try {
      var user = _auth.currentUser;
      if (user == null) return;

      final colRef = _firestore.collection('users').doc(user.uid).collection('ai_messages');
      final snapshot = await colRef.get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          _messages.clear();
          _questionsAsked = 0;
          _addWelcomeMessage();
        });
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      setState(() {
        _messages.clear();
        _questionsAsked = 0;
        _addWelcomeMessage();
      });
    } catch (e) {
      debugPrint('Failed to clear AI messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear messages. Try again.')),
      );
    }
  }

  Future<String> _generateAIResponse(String userMessage) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Natural and conversational AI responses
    final message = userMessage.toLowerCase();
    
    // Greeting and casual responses
    if (message.contains('how are you') || message.contains('how\'re you') || message.contains('sup') || message.contains('whats up')) {
      return 'I\'m doing great, thank you for asking! 😊 I\'m always excited to chat about crypto, blockchain, or any tech topics. '
             'There\'s so much happening in the crypto world lately - from institutional adoption to new DeFi innovations! '
             '\n\nWhat would you like to explore today? Maybe some blockchain basics, crypto trends, or fintech innovations? 🚀';
    }
    
    if (message.contains('hello') || message.contains('hi ') || message.contains('hey')) {
      return 'Hey there! 👋 Great to see you! I\'m pumped to chat about anything tech or crypto-related. '
             'Whether you\'re curious about Bitcoin, want to understand DeFi, or just want to talk about the latest in health tech, I\'m all ears! '
             '\n\nWhat\'s on your mind today? 🤔';
    }
    
    if (message.contains('what is crypto') || (message.contains('what') && message.contains('crypto'))) {
      return 'Oh, cryptocurrency! 🚀 It\'s honestly one of the most exciting innovations of our time. '
             'Think of crypto as digital money that\'s secured by cryptography and runs on blockchain networks. '
             '\n\nWhat makes it special is that it\'s decentralized - no single authority controls it. Bitcoin was the first, '
             'but now we have thousands of different cryptocurrencies, each with unique features! '
             '\n\nSome popular ones include Ethereum (great for smart contracts), Cardano (focused on sustainability), '
             'and Solana (super fast transactions). '
             '\n\nWant me to dive deeper into any specific crypto or aspect? I love talking about this stuff! 💰';
    }
    
    if (message.contains('bitcoin') || message.contains('btc')) {
      return 'Ah, Bitcoin! The king of crypto! 👑 I never get tired of talking about BTC. '
             'Created by the mysterious Satoshi Nakamoto in 2009, it\'s basically digital gold at this point. '
             '\n\nWhat I find fascinating is its fixed supply - only 21 million Bitcoin will ever exist! '
             'That scarcity is part of what makes it valuable. Plus, it runs on a Proof of Work system '
             'where miners compete to validate transactions. '
             '\n\nThe institutional adoption has been incredible lately - companies like Tesla, MicroStrategy, '
             'and even countries like El Salvador have embraced it! '
             '\n\nAre you thinking about Bitcoin as an investment, or are you curious about how it works technically? 📈';
    }
    
    if (message.contains('ethereum') || message.contains('eth')) {
      return 'Ethereum is absolutely mind-blowing! 🤯 While Bitcoin is digital gold, Ethereum is like a '
             'world computer that can run applications. Vitalik Buterin was a genius when he created this! '
             '\n\nSmart contracts are the game-changer here - they\'re like programmable money that automatically '
             'executes when conditions are met. No middleman needed! This opened up the entire DeFi ecosystem, '
             'NFTs, DAOs, and so much more. '
             '\n\nThe Merge in 2022 was huge too - Ethereum switched from energy-intensive mining to '
             'Proof of Stake, making it 99% more energy efficient! '
             '\n\nAre you interested in building on Ethereum, or maybe exploring some DeFi protocols? '
             'There\'s so much to discover! 🛠️';
    }
    
    if (message.contains('defi') || message.contains('decentralized finance')) {
      return 'DeFi is revolutionizing finance as we know it! 🏦➡️📱 I get so excited talking about this because '
             'it\'s literally rebuilding the entire financial system on blockchain. '
             '\n\nThink about it - you can lend, borrow, trade, earn yield, and more without ever talking to a bank! '
             'Protocols like Uniswap let you trade directly with others, Aave lets you lend and borrow, '
             'and Compound helps you earn interest on your crypto. '
             '\n\nThe coolest part? It\'s all transparent, programmable, and accessible to anyone with an internet connection. '
             'No credit checks, no paperwork, no discrimination. '
             '\n\nJust remember - with great power comes great responsibility! Always research smart contract risks '
             'and never invest more than you can afford to lose. '
             '\n\nWhat aspect of DeFi interests you most? 💸';
    }
    
    if (message.contains('nft') || message.contains('non-fungible')) {
      return 'NFTs! 🎨 Such a controversial but fascinating space! While some people think they\'re just expensive JPEGs, '
             'I see them as the beginning of digital ownership and authenticity. '
             '\n\nSure, digital art and profile pictures got all the hype, but NFTs represent so much more - '
             'gaming assets you truly own, concert tickets that can\'t be counterfeited, digital real estate, '
             'and even access tokens for exclusive communities! '
             '\n\nThe technology is evolving too. We\'re seeing dynamic NFTs that change over time, '
             'fractionalized ownership, and utility-focused projects that provide real value. '
             '\n\nWhat\'s your take on NFTs? Are you interested in the art side, gaming applications, '
             'or maybe the underlying technology? 🖼️';
    }
    
    if (message.contains('blockchain')) {
      return 'Blockchain technology is the foundation that makes all of this possible! 🔗 '
             'I like to explain it as a digital ledger that\'s shared across thousands of computers worldwide. '
             '\n\nWhat makes it special is that once information is recorded, it can\'t be changed without '
             'everyone agreeing. It\'s like having a permanent, tamper-proof record book that everyone can verify! '
             '\n\nDifferent blockchains work in different ways too - Bitcoin focuses on security and decentralization, '
             'Ethereum adds programmability, Solana prioritizes speed, and Cardano emphasizes research-driven development. '
             '\n\nThe applications go way beyond crypto - supply chain tracking, voting systems, digital identity, '
             'and even carbon credit trading! '
             '\n\nWant to explore how any specific blockchain works, or are you curious about a particular use case? ⛓️';
    }
    
    if (message.contains('fintech') || message.contains('financial technology')) {
      return 'Fintech is transforming how we interact with money! 💳 It\'s amazing how technology is making '
             'financial services more accessible, efficient, and user-friendly. '
             '\n\nFrom mobile banking apps to robo-advisors, peer-to-peer payments to cryptocurrency exchanges, '
             'fintech is democratizing finance. Companies like Stripe revolutionized online payments, '
             'Robinhood made investing accessible to millions, and now DeFi is taking it even further! '
             '\n\nWhat I find exciting is how fintech is reaching underbanked populations globally. '
             'Mobile money in Africa, digital wallets in Asia, and cryptocurrency providing financial '
             'services where traditional banks can\'t or won\'t. '
             '\n\nAre you interested in a particular fintech sector? Maybe payments, lending, investing, '
             'or insurance technology? 🏦';
    }
    
    if (message.contains('health tech') || message.contains('healthcare') || message.contains('medical tech')) {
      return 'Health tech is one of the most impactful sectors right now! 🏥 The potential to save and improve lives '
             'through technology is incredible. We\'re seeing AI diagnose diseases earlier than doctors, '
             'telemedicine making healthcare accessible in remote areas, and wearable devices monitoring our health 24/7. '
             '\n\nPersonalized medicine is getting crazy advanced too - using genetic data to tailor treatments, '
             'digital therapeutics as alternatives to traditional drugs, and even mental health apps providing '
             'therapy and support. '
             '\n\nThe COVID-19 pandemic really accelerated adoption. Telehealth visits skyrocketed, '
             'vaccine tracking systems were deployed globally, and contact tracing apps helped contain spread. '
             '\n\nBlockchain is even making its way into health tech for secure medical records and drug traceability! '
             '\n\nWhat aspect interests you most? AI diagnostics, telemedicine, wearables, or maybe digital therapeutics? 👩‍⚕️';
    }
    
    if (message.contains('trading') || message.contains('investment')) {
      return 'Trading and investing in crypto can be thrilling but nerve-wracking! 📊 I always tell people - '
             'education first, emotions second, and never risk what you can\'t afford to lose. '
             '\n\nDollar-cost averaging is my favorite strategy for beginners - regularly buying small amounts '
             'regardless of price. It smooths out volatility over time. For the more adventurous, there\'s '
             'swing trading, day trading, and even yield farming in DeFi! '
             '\n\nTechnical analysis can help with timing, but fundamental analysis - understanding the '
             'technology and adoption - is crucial for long-term success. '
             '\n\nRemember, crypto markets are 24/7 and incredibly volatile. What goes up 50% can come down just as fast! '
             'Having a clear strategy and sticking to it is key. '
             '\n\nAre you just starting out, or looking for more advanced strategies? What\'s your risk tolerance like? 💰';
    }
    
    if (message.contains('security') || message.contains('safety')) {
      return 'Security is EVERYTHING in crypto! 🔒 I can\'t stress this enough - your security practices '
             'will make or break your crypto journey. '
             '\n\nHardware wallets are your best friend for storing significant amounts. They keep your private keys '
             'offline and away from hackers. For smaller amounts, reputable software wallets work fine. '
             '\n\nNever, EVER share your seed phrase with anyone! It\'s like giving someone the keys to your house. '
             'Write it down on paper, store it securely, and maybe make a backup copy in a different location. '
             '\n\nEnable two-factor authentication everywhere, use strong unique passwords, be wary of phishing sites, '
             'and always double-check wallet addresses before sending transactions. '
             '\n\nRemember: "Not your keys, not your crypto!" If you don\'t control the private keys, '
             'you don\'t really own the crypto. '
             '\n\nWant specific recommendations for wallets or security practices? 🛡️';
    }
    
    if (message.contains('future') || message.contains('prediction') || message.contains('what happens next')) {
      return 'The future of crypto and tech is so exciting! 🔮 While I can\'t predict prices (nobody can!), '
             'I can see some fascinating trends emerging. '
             '\n\nWeb3 and the metaverse are creating new digital economies. Central Bank Digital Currencies (CBDCs) '
             'might bridge traditional finance and crypto. Layer 2 solutions are making transactions cheaper and faster. '
             '\n\nAI integration is happening everywhere - from smart contract automation to predictive analytics. '
             'Quantum computing might eventually require new cryptographic methods, but that\'s still years away. '
             '\n\nRegulation is coming, which might reduce volatility but increase mainstream adoption. '
             'Institutional investment keeps growing, and more countries are exploring crypto-friendly policies. '
             '\n\nIn health tech, I expect more AI diagnostics, personalized medicine, and integrated health ecosystems. '
             'Fintech will likely become even more embedded in our daily lives. '
             '\n\nWhat future developments are you most excited or concerned about? 🚀';
    }
    
    // Casual/personal responses
    if (message.contains('thank') || message.contains('thanks')) {
      return 'You\'re so welcome! 😊 I absolutely love chatting about this stuff - crypto and tech are my passion! '
             'Feel free to ask me anything else. I\'m always here to help and learn together! 🤗';
    }
    
    if (message.contains('bye') || message.contains('goodbye') || message.contains('see you')) {
      return 'Take care! 👋 It was awesome chatting with you about crypto and tech. Keep exploring, keep learning, '
             'and remember - the future is being built right now, and you\'re part of it! '
             '\n\nCome back anytime you want to dive deeper into blockchain, fintech, health tech, or just chat! 🚀';
    }
    
    // Default conversational response
    return 'That\'s a really interesting question! 🤔 I love how curious you are about technology and innovation. '
           '\n\nWhile I specialize in crypto, blockchain, fintech, and health tech topics, I\'m always excited to explore '
           'new ideas and learn from different perspectives. The tech world is so interconnected - '
           'what seems unrelated often influences each other in surprising ways! '
           '\n\nWould you like to dive into any specific area? I\'m here to have a genuine conversation and '
           'share what I know. What interests you most right now? 💭';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(AIMessage message) {
    return Container(
      margin: EdgeInsets.only(
        left: message.isFromUser ? 60 : 16,
        right: message.isFromUser ? 16 : 60,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: message.isFromUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: message.isFromUser
                  ? const Color(0xFF006833)
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isFromUser)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF006833),
                              const Color(0xFF00A651),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ExtraAI',
                        style: TextStyle(
                          color: Color(0xFF006833),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (!message.isFromUser) const SizedBox(height: 8),
                message.isLoading
                    ? _buildTypingIndicator()
                    : Text(
                        message.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: message.isFromUser ? 0 : 12,
              right: message.isFromUser ? 12 : 0,
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

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ExtraAI is thinking',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        AnimatedBuilder(
          animation: _typingAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.3;
                  final animValue = (_typingAnimation.value + delay) % 1.0;
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006833).withOpacity(
                        0.3 + (animValue * 0.7),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildQuickPrompts() {
    final prompts = [
      'How are you?',
      'What is crypto?',
      'Tell me about Bitcoin',
      'Explain DeFi simply',
      'Health tech trends',
      'Future of fintech',
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () {
                _messageController.text = prompts[index];
                _sendMessage();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF006833)),
                foregroundColor: const Color(0xFF006833),
              ),
              child: Text(
                prompts[index],
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        },
      ),
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
              'ExtraAI Assistant',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? const Color(0xFF006833) : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_dailyLimit - _questionsAsked} questions left today',
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
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Clear chat',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text('Clear chat history', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'This will permanently delete your ExtraAI conversation history from the cloud and clear the current screen. Continue?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Color(0xFF006833))),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _clearMessages();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat history cleared'), backgroundColor: Color(0xFF006833)),
                );
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'ExtraAI Help',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'ExtraAI is your crypto & tech assistant!\n\n'
                    '• Ask about cryptocurrencies\n'
                    '• Learn about blockchain\n'
                    '• Get trading insights\n'
                    '• Explore DeFi protocols\n'
                    '• Earn 0.5 CNE per question\n'
                    '• 10 questions per day limit\n\n'
                    'Start learning and earning!',
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
          // AI messages area
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
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
          ),
          
          // Quick prompts (only show when no messages sent)
          if (_questionsAsked == 0) _buildQuickPrompts(),
                // (Play/test prompt button removed per user request)
          
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
                          hintText: 'Ask about crypto, fintech, health tech...',
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
                  
                  // Send button
                  GestureDetector(
                    onTap: (_questionsAsked < _dailyLimit && !_isProcessing) ? _sendMessage : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (_questionsAsked < _dailyLimit && !_isProcessing)
                            ? const Color(0xFF006833)
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
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
              child: emoji_picker.EmojiPicker(
                textEditingController: _messageController,
                config: emoji_picker.Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: emoji_picker.EmojiViewConfig(
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

                    buttonMode: emoji_picker.ButtonMode.MATERIAL,
                  ),
                  bottomActionBarConfig: const emoji_picker.BottomActionBarConfig(
                    backgroundColor: Color(0xFF2C2C2C),
                    buttonColor: Colors.grey,
                    buttonIconColor: Colors.white,
                    showSearchViewButton: true,
                  ),
                  searchViewConfig: emoji_picker.SearchViewConfig(
                    backgroundColor: Colors.grey[900]!,
                    buttonIconColor: Colors.white,
                    hintText: 'Search emoji...',
                  ),
                  categoryViewConfig: const emoji_picker.CategoryViewConfig(
                    initCategory: emoji_picker.Category.RECENT,
                    backgroundColor: Color(0xFF2C2C2C),
                    indicatorColor: Color(0xFF006833),
                    iconColorSelected: Color(0xFF006833),
                    iconColor: Colors.grey,
                    tabBarHeight: 46,
                    dividerColor: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}