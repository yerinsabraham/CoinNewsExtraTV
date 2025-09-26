import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

class ExtraAiChat extends StatefulWidget {
  const ExtraAiChat({super.key});

  @override
  State<ExtraAiChat> createState() => _ExtraAiChatState();
}

class _ExtraAiChatState extends State<ExtraAiChat> {
  final TextEditingController _messageController = TextEditingController();
  final List<AiChatMessage> _messages = [];
  
  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      AiChatMessage(
        content: "Hi! I'm CNETV AI, your crypto assistant. Ask me about blockchain, DeFi, and crypto!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text.trim();
    _messageController.clear();
    
    setState(() {
      _messages.add(AiChatMessage(
        content: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      
      // Simple response for demo
      _messages.add(AiChatMessage(
        content: "Thanks for your message! I'm currently in demo mode. Full AI features coming soon with proper API setup.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Extra AI', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask about crypto...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
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
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFF006833),
              child: Icon(FeatherIcons.cpu, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF006833) : Colors.grey[800],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(FeatherIcons.user, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class AiChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  AiChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}