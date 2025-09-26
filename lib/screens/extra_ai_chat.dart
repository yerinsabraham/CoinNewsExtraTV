import 'package:flutter/material.dart';import 'package:flutter/material.dart';

import 'package:feather_icons/feather_icons.dart';import 'package:feather_icons/feather_icons.dart';

import 'package:http/http.dart' as http;import 'package:http/http.dart' as http;

import 'dart:convert';import 'dart:convert';



class ExtraAiChat extends StatefulWidget {class ExtraAiChat extends StatefulWidget {

  const ExtraAiChat({super.key});  const ExtraAiChat({super.key});



  @override  @override

  State<ExtraAiChat> createState() => _ExtraAiChatState();  State<ExtraAiChat> createState() => _ExtraAiChatState();

}}



class _ExtraAiChatState extends State<ExtraAiChat> {class _ExtraAiChatState extends State<ExtraAiChat> {

  final TextEditingController _messageController = TextEditingController();  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();  final ScrollController _scrollController = ScrollController();

  final List<AiChatMessage> _messages = [];  final List<AiChatMessage> _messages = [];

  bool _isLoading = false;  bool _isLoading = false;

    

  // TODO: Add your OpenAI API key to environment variables or secure storage  // TODO: Add your OpenAI API key to environment variables or secure storage

  static const String _openaiApiKey = 'YOUR_OPENAI_API_KEY_HERE';  static const String _openaiApiKey = 'YOUR_OPENAI_API_KEY_HERE';

    

  @override  @override

  void initState() {  void initState() {

    super.initState();    super.initState();

    // Add welcome message    // Add welcome message

    _messages.add(    _messages.add(

      AiChatMessage(      AiChatMessage(

        content: "Hi! I'm CNETV AI, your crypto and fintech assistant. I can help you with:\n\n• Market analysis and insights\n• Blockchain technology explanations\n• DeFi protocols and strategies\n• Trading concepts and risk management\n• Web3 and crypto project analysis\n• Technical definitions and concepts\n\nWhat would you like to know about crypto today?",        content: "Hi! I'm CNETV AI, your crypto and fintech assistant. I can help you with:\n\n• Market analysis and insights\n• Blockchain technology explanations\n• DeFi protocols and strategies\n• Trading concepts and risk management\n• Web3 and crypto project analysis\n• Technical definitions and concepts\n\nWhat would you like to know about crypto today?",

        isUser: false,        isUser: false,

        timestamp: DateTime.now(),        timestamp: DateTime.now(),

      ),      ),

    );    );

  }  }



  Future<void> _sendMessage() async {  Future<void> _sendMessage() async {

    if (_messageController.text.trim().isEmpty) return;    if (_messageController.text.trim().isEmpty) return;

        

    final userMessage = _messageController.text.trim();    final userMessage = _messageController.text.trim();

    _messageController.clear();    _messageController.clear();

        

    // Add user message    // Add user message

    setState(() {    setState(() {

      _messages.add(AiChatMessage(      _messages.add(AiChatMessage(

        content: userMessage,        content: userMessage,

        isUser: true,        isUser: true,

        timestamp: DateTime.now(),        timestamp: DateTime.now(),

      ));      ));

      _isLoading = true;      _isLoading = true;

    });    });

        

    _scrollToBottom();    _scrollToBottom();

        

    try {    try {

      final aiResponse = await _getAiResponse(userMessage);      final aiResponse = await _getAiResponse(userMessage);

            

      setState(() {      setState(() {

        _messages.add(AiChatMessage(        _messages.add(AiChatMessage(

          content: aiResponse,          content: aiResponse,

          isUser: false,          isUser: false,

          timestamp: DateTime.now(),          timestamp: DateTime.now(),

        ));        ));

        _isLoading = false;        _isLoading = false;

      });      });

            

      _scrollToBottom();      _scrollToBottom();

    } catch (e) {    } catch (e) {

      setState(() {      setState(() {

        _messages.add(AiChatMessage(        _messages.add(AiChatMessage(

          content: "I'm sorry, I'm having trouble connecting right now. Please try again in a moment. In the meantime, here are some quick crypto insights:\n\n• Bitcoin remains the store of value in crypto\n• DeFi yields can be attractive but come with smart contract risks\n• Always DYOR (Do Your Own Research) before investing\n• Dollar-cost averaging is a popular strategy for crypto investing",          content: "I'm sorry, I'm having trouble connecting right now. Please try again in a moment. In the meantime, here are some quick crypto insights:\n\n• Bitcoin remains the store of value in crypto\n• DeFi yields can be attractive but come with smart contract risks\n• Always DYOR (Do Your Own Research) before investing\n• Dollar-cost averaging is a popular strategy for crypto investing",

          isUser: false,          isUser: false,

          timestamp: DateTime.now(),          timestamp: DateTime.now(),

        ));        ));

        _isLoading = false;        _isLoading = false;

      });      });

            

      _scrollToBottom();      _scrollToBottom();

    }    }

  }  }



  Future<String> _getAiResponse(String message) async {  Future<String> _getAiResponse(String message) async {

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

        

    final systemPrompt = '''You are CNETV AI, a specialized cryptocurrency and fintech assistant. You provide expert knowledge on:    final systemPrompt = '''You are CNETV AI, a specialized cryptocurrency and fintech assistant. You provide expert knowledge on:



- Cryptocurrency market analysis and trends- Cryptocurrency market analysis and trends

- Blockchain technology and protocols- Blockchain technology and protocols

- DeFi (Decentralized Finance) strategies and risks- DeFi (Decentralized Finance) strategies and risks

- Trading concepts and risk management- Trading concepts and risk management

- Web3 technologies and dApps- Web3 technologies and dApps

- Fintech innovations and solutions- Fintech innovations and solutions

- Technical definitions in crypto/blockchain space- Technical definitions in crypto/blockchain space



Keep responses informative but conversational. Use emojis sparingly. Always encourage users to do their own research (DYOR) for investment decisions. Focus on education rather than specific financial advice.''';Keep responses informative but conversational. Use emojis sparingly. Always encourage users to do their own research (DYOR) for investment decisions. Focus on education rather than specific financial advice.''';



    final response = await http.post(    final response = await http.post(

      url,      url,

      headers: {      headers: {

        'Content-Type': 'application/json',        'Content-Type': 'application/json',

        'Authorization': 'Bearer $_openaiApiKey',        'Authorization': 'Bearer $_openaiApiKey',

      },      },

      body: jsonEncode({      body: jsonEncode({

        'model': 'gpt-3.5-turbo',        'model': 'gpt-3.5-turbo',

        'messages': [        'messages': [

          {'role': 'system', 'content': systemPrompt},          {'role': 'system', 'content': systemPrompt},

          {'role': 'user', 'content': message},          {'role': 'user', 'content': message},

        ],        ],

        'max_tokens': 500,        'max_tokens': 500,

        'temperature': 0.7,        'temperature': 0.7,

      }),      }),

    );    );



    if (response.statusCode == 200) {    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);      final data = jsonDecode(response.body);

      return data['choices'][0]['message']['content'].toString().trim();      return data['choices'][0]['message']['content'].toString().trim();

    } else {    } else {

      throw Exception('Failed to get AI response');      throw Exception('Failed to get AI response');

    }    }

  }  }



  void _scrollToBottom() {  void _scrollToBottom() {

    WidgetsBinding.instance.addPostFrameCallback((_) {    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (_scrollController.hasClients) {      if (_scrollController.hasClients) {

        _scrollController.animateTo(        _scrollController.animateTo(

          _scrollController.position.maxScrollExtent,          _scrollController.position.maxScrollExtent,

          duration: const Duration(milliseconds: 300),          duration: const Duration(milliseconds: 300),

          curve: Curves.easeOut,          curve: Curves.easeOut,

        );        );

      }      }

    });    });

  }  }



  @override  @override

  Widget build(BuildContext context) {  Widget build(BuildContext context) {

    return Scaffold(    return Scaffold(

      backgroundColor: Colors.black,      backgroundColor: Colors.black,

      appBar: AppBar(      appBar: AppBar(

        backgroundColor: Colors.black,        backgroundColor: Colors.black,

        elevation: 0,        elevation: 0,

        leading: IconButton(        leading: IconButton(

          icon: const Icon(Icons.arrow_back, color: Colors.white),          icon: const Icon(Icons.arrow_back, color: Colors.white),

          onPressed: () => Navigator.pop(context),          onPressed: () => Navigator.pop(context),

        ),        ),

        title: Row(        title: Row(

          children: [          children: [

            Container(            Container(

              padding: const EdgeInsets.all(6),              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(              decoration: BoxDecoration(

                color: const Color(0xFF006833),                color: const Color(0xFF006833),

                borderRadius: BorderRadius.circular(6),                borderRadius: BorderRadius.circular(6),

              ),              ),

              child: const Icon(              child: const Icon(

                FeatherIcons.cpu,                FeatherIcons.cpu,

                color: Colors.white,                color: Colors.white,

                size: 16,                size: 16,

              ),              ),

            ),            ),

            const SizedBox(width: 8),            const SizedBox(width: 8),

            const Text(            const Text(

              'Extra AI',              'Extra AI',

              style: TextStyle(              style: TextStyle(

                color: Colors.white,                color: Colors.white,

                fontSize: 18,                fontSize: 18,

                fontWeight: FontWeight.bold,                fontWeight: FontWeight.bold,

                fontFamily: 'Lato',                fontFamily: 'Lato',

              ),              ),

            ),            ),

            const SizedBox(width: 4),            const SizedBox(width: 4),

            Container(            Container(

              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

              decoration: BoxDecoration(              decoration: BoxDecoration(

                color: Colors.green,                color: Colors.green,

                borderRadius: BorderRadius.circular(3),                borderRadius: BorderRadius.circular(3),

              ),              ),

              child: const Text(              child: const Text(

                'ONLINE',                'ONLINE',

                style: TextStyle(                style: TextStyle(

                  color: Colors.white,                  color: Colors.white,

                  fontSize: 8,                  fontSize: 8,

                  fontWeight: FontWeight.bold,                  fontWeight: FontWeight.bold,

                ),                ),

              ),              ),

            ),            ),

          ],          ],

        ),        ),

        actions: [        actions: [

          IconButton(          IconButton(

            icon: const Icon(FeatherIcons.moreVertical, color: Colors.white),            icon: const Icon(FeatherIcons.moreVertical, color: Colors.white),

            onPressed: () {            onPressed: () {

              _showOptionsMenu();              _showOptionsMenu();

            },            },

          ),          ),

        ],        ],

      ),      ),

      body: Column(      body: Column(

        children: [        children: [

          // Messages list          // Messages list

          Expanded(          Expanded(

            child: ListView.builder(            child: ListView.builder(

              controller: _scrollController,              controller: _scrollController,

              padding: const EdgeInsets.all(16),              padding: const EdgeInsets.all(16),

              itemCount: _messages.length + (_isLoading ? 1 : 0),              itemCount: _messages.length + (_isLoading ? 1 : 0),

              itemBuilder: (context, index) {              itemBuilder: (context, index) {

                if (index == _messages.length && _isLoading) {                if (index == _messages.length && _isLoading) {

                  return _buildTypingIndicator();                  return _buildTypingIndicator();

                }                }

                return _buildMessageBubble(_messages[index]);                return _buildMessageBubble(_messages[index]);

              },              },

            ),            ),

          ),          ),

                    

          // Message input          // Message input

          Container(          Container(

            padding: const EdgeInsets.all(16),            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(            decoration: BoxDecoration(

              color: Colors.grey[900],              color: Colors.grey[900],

              border: Border(              border: Border(

                top: BorderSide(color: Colors.grey[800]!),                top: BorderSide(color: Colors.grey[800]!),

              ),              ),

            ),            ),

            child: SafeArea(            child: SafeArea(

              child: Row(              child: Row(

                children: [                children: [

                  Expanded(                  Expanded(

                    child: TextField(                    child: TextField(

                      controller: _messageController,                      controller: _messageController,

                      style: const TextStyle(color: Colors.white),                      style: const TextStyle(color: Colors.white),

                      maxLines: null,                      maxLines: null,

                      textCapitalization: TextCapitalization.sentences,                      textCapitalization: TextCapitalization.sentences,

                      decoration: InputDecoration(                      decoration: InputDecoration(

                        hintText: 'Ask about crypto, DeFi, trading...',                        hintText: 'Ask about crypto, DeFi, trading...',

                        hintStyle: TextStyle(color: Colors.grey[500]),                        hintStyle: TextStyle(color: Colors.grey[500]),

                        filled: true,                        filled: true,

                        fillColor: Colors.grey[800],                        fillColor: Colors.grey[800],

                        border: OutlineInputBorder(                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(24),                          borderRadius: BorderRadius.circular(24),

                          borderSide: BorderSide.none,                          borderSide: BorderSide.none,

                        ),                        ),

                        contentPadding: const EdgeInsets.symmetric(                        contentPadding: const EdgeInsets.symmetric(

                          horizontal: 16,                          horizontal: 16,

                          vertical: 12,                          vertical: 12,

                        ),                        ),

                      ),                      ),

                      onSubmitted: (_) => _sendMessage(),                      onSubmitted: (_) => _sendMessage(),

                    ),                    ),

                  ),                  ),

                  const SizedBox(width: 8),                  const SizedBox(width: 8),

                  CircleAvatar(                  CircleAvatar(

                    backgroundColor: _messageController.text.trim().isNotEmpty                     backgroundColor: _messageController.text.trim().isNotEmpty 

                        ? const Color(0xFF006833)                         ? const Color(0xFF006833) 

                        : Colors.grey[600],                        : Colors.grey[600],

                    child: IconButton(                    child: IconButton(

                      icon: Icon(                      icon: Icon(

                        _isLoading ? FeatherIcons.clock : Icons.send,                        _isLoading ? FeatherIcons.clock : Icons.send,

                        color: Colors.white,                        color: Colors.white,

                        size: 18,                        size: 18,

                      ),                      ),

                      onPressed: _isLoading ? null : _sendMessage,                      onPressed: _isLoading ? null : _sendMessage,

                    ),                    ),

                  ),                  ),

                ],                ],

              ),              ),

            ),            ),

          ),          ),

        ],        ],

      ),      ),

    );    );

  }  }



  Widget _buildMessageBubble(AiChatMessage message) {  Widget _buildMessageBubble(AiChatMessage message) {

    return Container(    return Container(

      margin: const EdgeInsets.only(bottom: 16),      margin: const EdgeInsets.only(bottom: 16),

      child: Row(      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,

        children: [        children: [

          if (!message.isUser) ...[          if (!message.isUser) ...[

            Container(            Container(

              padding: const EdgeInsets.all(8),              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(              decoration: BoxDecoration(

                color: const Color(0xFF006833),                color: const Color(0xFF006833),

                borderRadius: BorderRadius.circular(16),                borderRadius: BorderRadius.circular(16),

              ),              ),

              child: const Icon(              child: const Icon(

                FeatherIcons.cpu,                FeatherIcons.cpu,

                color: Colors.white,                color: Colors.white,

                size: 16,                size: 16,

              ),              ),

            ),            ),

            const SizedBox(width: 8),            const SizedBox(width: 8),

          ],          ],

          Flexible(          Flexible(

            child: Container(            child: Container(

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

              decoration: BoxDecoration(              decoration: BoxDecoration(

                color: message.isUser                 color: message.isUser 

                    ? const Color(0xFF006833)                    ? const Color(0xFF006833)

                    : Colors.grey[800],                    : Colors.grey[800],

                borderRadius: BorderRadius.circular(18),                borderRadius: BorderRadius.circular(18),

              ),              ),

              child: Column(              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,                crossAxisAlignment: CrossAxisAlignment.start,

                children: [                children: [

                  Text(                  Text(

                    message.content,                    message.content,

                    style: TextStyle(                    style: TextStyle(

                      color: message.isUser ? Colors.white : Colors.white,                      color: message.isUser ? Colors.white : Colors.white,

                      fontSize: 15,                      fontSize: 15,

                      height: 1.4,                      height: 1.4,

                      fontFamily: 'Lato',                      fontFamily: 'Lato',

                    ),                    ),

                  ),                  ),

                  const SizedBox(height: 4),                  const SizedBox(height: 4),

                  Text(                  Text(

                    _formatTime(message.timestamp),                    _formatTime(message.timestamp),

                    style: TextStyle(                    style: TextStyle(

                      color: message.isUser                       color: message.isUser 

                          ? Colors.white.withOpacity(0.7)                          ? Colors.white.withOpacity(0.7)

                          : Colors.grey[400],                          : Colors.grey[400],

                      fontSize: 11,                      fontSize: 11,

                      fontFamily: 'Lato',                      fontFamily: 'Lato',

                    ),                    ),

                  ),                  ),

                ],                ],

              ),              ),

            ),            ),

          ),          ),

          if (message.isUser) ...[          if (message.isUser) ...[

            const SizedBox(width: 8),            const SizedBox(width: 8),

            CircleAvatar(            CircleAvatar(

              backgroundColor: Colors.grey[600],              backgroundColor: Colors.grey[600],

              radius: 16,              radius: 16,

              child: const Icon(              child: const Icon(

                FeatherIcons.user,                FeatherIcons.user,

                color: Colors.white,                color: Colors.white,

                size: 16,                size: 16,

              ),              ),

            ),            ),

          ],          ],

        ],        ],

      ),      ),

    );    );

  }  }



  Widget _buildTypingIndicator() {  Widget _buildTypingIndicator() {

    return Container(    return Container(

      margin: const EdgeInsets.only(bottom: 16),      margin: const EdgeInsets.only(bottom: 16),

      child: Row(      child: Row(

        children: [        children: [

          Container(          Container(

            padding: const EdgeInsets.all(8),            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(            decoration: BoxDecoration(

              color: const Color(0xFF006833),              color: const Color(0xFF006833),

              borderRadius: BorderRadius.circular(16),              borderRadius: BorderRadius.circular(16),

            ),            ),

            child: const Icon(            child: const Icon(

              FeatherIcons.cpu,              FeatherIcons.cpu,

              color: Colors.white,              color: Colors.white,

              size: 16,              size: 16,

            ),            ),

          ),          ),

          const SizedBox(width: 8),          const SizedBox(width: 8),

          Container(          Container(

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

            decoration: BoxDecoration(            decoration: BoxDecoration(

              color: Colors.grey[800],              color: Colors.grey[800],

              borderRadius: BorderRadius.circular(18),              borderRadius: BorderRadius.circular(18),

            ),            ),

            child: Row(            child: Row(

              mainAxisSize: MainAxisSize.min,              mainAxisSize: MainAxisSize.min,

              children: [              children: [

                SizedBox(                SizedBox(

                  width: 20,                  width: 20,

                  height: 20,                  height: 20,

                  child: CircularProgressIndicator(                  child: CircularProgressIndicator(

                    strokeWidth: 2,                    strokeWidth: 2,

                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),

                  ),                  ),

                ),                ),

                const SizedBox(width: 8),                const SizedBox(width: 8),

                Text(                Text(

                  'AI is thinking...',                  'AI is thinking...',

                  style: TextStyle(                  style: TextStyle(

                    color: Colors.grey[400],                    color: Colors.grey[400],

                    fontSize: 14,                    fontSize: 14,

                    fontFamily: 'Lato',                    fontFamily: 'Lato',

                  ),                  ),

                ),                ),

              ],              ],

            ),            ),

          ),          ),

        ],        ],

      ),      ),

    );    );

  }  }



  String _formatTime(DateTime timestamp) {  String _formatTime(DateTime timestamp) {

    final now = DateTime.now();    final now = DateTime.now();

    final difference = now.difference(timestamp);    final difference = now.difference(timestamp);

        

    if (difference.inMinutes < 1) {    if (difference.inMinutes < 1) {

      return 'Just now';      return 'Just now';

    } else if (difference.inMinutes < 60) {    } else if (difference.inMinutes < 60) {

      return '${difference.inMinutes}m ago';      return '${difference.inMinutes}m ago';

    } else {    } else {

      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    }    }

  }  }



  void _showOptionsMenu() {  void _showOptionsMenu() {

    showModalBottomSheet(    showModalBottomSheet(

      context: context,      context: context,

      backgroundColor: Colors.grey[900],      backgroundColor: Colors.grey[900],

      builder: (context) => Container(      builder: (context) => Container(

        padding: const EdgeInsets.all(20),        padding: const EdgeInsets.all(20),

        child: Column(        child: Column(

          mainAxisSize: MainAxisSize.min,          mainAxisSize: MainAxisSize.min,

          children: [          children: [

            ListTile(            ListTile(

              leading: const Icon(FeatherIcons.trash2, color: Colors.red),              leading: const Icon(FeatherIcons.trash2, color: Colors.red),

              title: const Text('Clear Chat', style: TextStyle(color: Colors.white)),              title: const Text('Clear Chat', style: TextStyle(color: Colors.white)),

              onTap: () {              onTap: () {

                Navigator.pop(context);                Navigator.pop(context);

                _clearChat();                _clearChat();

              },              },

            ),            ),

            ListTile(            ListTile(

              leading: const Icon(FeatherIcons.info, color: Colors.white),              leading: const Icon(FeatherIcons.info, color: Colors.white),

              title: const Text('About Extra AI', style: TextStyle(color: Colors.white)),              title: const Text('About Extra AI', style: TextStyle(color: Colors.white)),

              onTap: () {              onTap: () {

                Navigator.pop(context);                Navigator.pop(context);

                _showAboutDialog();                _showAboutDialog();

              },              },

            ),            ),

          ],          ],

        ),        ),

      ),      ),

    );    );

  }  }



  void _clearChat() {  void _clearChat() {

    setState(() {    setState(() {

      _messages.clear();      _messages.clear();

      _messages.add(      _messages.add(

        AiChatMessage(        AiChatMessage(

          content: "Chat cleared! I'm ready to help you with crypto and fintech questions. What would you like to know?",          content: "Chat cleared! I'm ready to help you with crypto and fintech questions. What would you like to know?",

          isUser: false,          isUser: false,

          timestamp: DateTime.now(),          timestamp: DateTime.now(),

        ),        ),

      );      );

    });    });

  }  }



  void _showAboutDialog() {  void _showAboutDialog() {

    showDialog(    showDialog(

      context: context,      context: context,

      builder: (context) => AlertDialog(      builder: (context) => AlertDialog(

        backgroundColor: Colors.grey[900],        backgroundColor: Colors.grey[900],

        title: const Text('About Extra AI', style: TextStyle(color: Colors.white)),        title: const Text('About Extra AI', style: TextStyle(color: Colors.white)),

        content: const Text(        content: const Text(

          'CNETV Extra AI is your specialized crypto and fintech assistant. Powered by advanced AI to help you understand blockchain technology, market analysis, and DeFi strategies.\n\nAlways remember to DYOR (Do Your Own Research) before making investment decisions.',          'CNETV Extra AI is your specialized crypto and fintech assistant. Powered by advanced AI to help you understand blockchain technology, market analysis, and DeFi strategies.\n\nAlways remember to DYOR (Do Your Own Research) before making investment decisions.',

          style: TextStyle(color: Colors.grey),          style: TextStyle(color: Colors.grey),

        ),        ),

        actions: [        actions: [

          TextButton(          TextButton(

            onPressed: () => Navigator.pop(context),            onPressed: () => Navigator.pop(context),

            child: const Text('Got it', style: TextStyle(color: Color(0xFF006833))),            child: const Text('Got it', style: TextStyle(color: Color(0xFF006833))),

          ),          ),

        ],        ],

      ),      ),

    );    );

  }  }

}}



class AiChatMessage {class AiChatMessage {

  final String content;  final String content;

  final bool isUser;  final bool isUser;

  final DateTime timestamp;  final DateTime timestamp;



  AiChatMessage({  AiChatMessage({

    required this.content,    required this.content,

    required this.isUser,    required this.isUser,

    required this.timestamp,    required this.timestamp,

  });  });

}}