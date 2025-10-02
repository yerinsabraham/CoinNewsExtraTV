import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/user_balance_service.dart';
import '../services/openai_service.dart';

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
  
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  
  bool _isConnected = true;
  int _questionsAsked = 0;
  final int _dailyLimit = 10;
  bool _isProcessing = false;

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
    
    _addWelcomeMessage();
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
        content: 'Hello! I\'m ExtraAI, your crypto and technology assistant. 🤖\n\n'
                'I can help you with:\n'
                '• Cryptocurrency analysis\n'
                '• Blockchain technology questions\n'
                '• Trading strategies\n'
                '• DeFi protocols\n'
                '• Market insights\n\n'
                'Ask me anything about crypto or tech!',
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
      // Use OpenAI service for real AI responses
      final aiResponse = await _openAIService.sendMessage(userMessage);
      
      setState(() {
        _messages.removeLast(); // Remove loading message
        _messages.add(AIMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: aiResponse,
          isFromUser: false,
          timestamp: DateTime.now(),
        ));
      });

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
          content: 'Sorry, I encountered an error. Please try again! 🤖',
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

  Future<String> _generateAIResponse(String userMessage) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock AI responses based on keywords (In production, use OpenAI API)
    final message = userMessage.toLowerCase();
    
    if (message.contains('bitcoin') || message.contains('btc')) {
      return 'Bitcoin (BTC) is the first and largest cryptocurrency by market cap. '
             'Key points:\n\n'
             '• Created by Satoshi Nakamoto in 2009\n'
             '• Limited supply of 21 million coins\n'
             '• Store of value and digital gold narrative\n'
             '• Proof of Work consensus mechanism\n\n'
             'Current market trends suggest continued institutional adoption. '
             'Remember to always DYOR (Do Your Own Research)! 📈';
    }
    
    if (message.contains('ethereum') || message.contains('eth')) {
      return 'Ethereum (ETH) is a decentralized platform for smart contracts. '
             'Key features:\n\n'
             '• Smart contract functionality\n'
             '• DeFi ecosystem foundation\n'
             '• NFT marketplace hub\n'
             '• Proof of Stake since The Merge\n'
             '• EIP-1559 fee burning mechanism\n\n'
             'Ethereum continues to be the leading smart contract platform with '
             'the largest developer ecosystem. 🛠️';
    }
    
    if (message.contains('defi') || message.contains('decentralized finance')) {
      return 'DeFi (Decentralized Finance) revolutionizes traditional finance:\n\n'
             '• Lending & Borrowing (Aave, Compound)\n'
             '• Decentralized Exchanges (Uniswap, SushiSwap)\n'
             '• Yield Farming opportunities\n'
             '• Liquidity Mining rewards\n'
             '• No intermediaries needed\n\n'
             'Always be cautious of smart contract risks and impermanent loss! ⚠️';
    }
    
    if (message.contains('nft') || message.contains('non-fungible')) {
      return 'NFTs (Non-Fungible Tokens) represent unique digital assets:\n\n'
             '• Digital art and collectibles\n'
             '• Gaming assets and avatars\n'
             '• Virtual real estate\n'
             '• Music and media rights\n'
             '• Utility and access tokens\n\n'
             'The NFT market is evolving with new use cases emerging daily! 🎨';
    }
    
    if (message.contains('trading') || message.contains('strategy')) {
      return 'Crypto trading strategies to consider:\n\n'
             '• Dollar Cost Averaging (DCA)\n'
             '• HODL for long-term gains\n'
             '• Technical analysis patterns\n'
             '• Risk management rules\n'
             '• Portfolio diversification\n\n'
             'Remember: Never invest more than you can afford to lose! '
             'Crypto markets are highly volatile. 📊';
    }
    
    if (message.contains('blockchain') || message.contains('technology')) {
      return 'Blockchain technology fundamentals:\n\n'
             '• Distributed ledger system\n'
             '• Cryptographic security\n'
             '• Consensus mechanisms\n'
             '• Immutable transaction records\n'
             '• Decentralized architecture\n\n'
             'Blockchain enables trustless transactions and programmable money. '
             'It\'s the foundation of Web3! ⛓️';
    }
    
    if (message.contains('wallet') || message.contains('security')) {
      return 'Crypto wallet security best practices:\n\n'
             '• Use hardware wallets for large amounts\n'
             '• Keep seed phrases offline and secure\n'
             '• Never share private keys\n'
             '• Enable 2FA on exchanges\n'
             '• Use reputable wallet providers\n\n'
             'Your keys, your crypto. Not your keys, not your crypto! 🔒';
    }
    
    // Default response for other questions
    return 'That\'s an interesting question about crypto/tech! While I\'d love to dive deeper, '
           'I recommend checking the latest research and community discussions for the most '
           'up-to-date information.\n\n'
           'Key resources:\n'
           '• CoinGecko & CoinMarketCap for data\n'
           '• GitHub for project development\n'
           '• Twitter for real-time updates\n'
           '• Discord/Telegram communities\n\n'
           'Always verify information from multiple sources! 🔍';
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
      'What is Bitcoin?',
      'Explain DeFi',
      'Trading strategies',
      'Blockchain basics',
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
                  // AI status indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006833).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: const Color(0xFF006833),
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
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
                          hintText: 'Ask about crypto or tech...',
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
        ],
      ),
    );
  }
}