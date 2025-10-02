import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // In production, this should be stored securely (environment variables, Firebase config, etc.)
  static const String _apiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessage(String message) async {
    try {
      // Check if API key is configured
      if (_apiKey == 'YOUR_OPENAI_API_KEY_HERE') {
        return _getDemoResponse(message);
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are CNETV AI, a helpful cryptocurrency and blockchain assistant. You specialize in answering questions about Bitcoin, Ethereum, DeFi, NFTs, trading, and blockchain technology. Keep your responses informative but concise.'
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        print('OpenAI API Error: ${response.statusCode} - ${response.body}');
        return _getErrorResponse();
      }
    } catch (e) {
      print('OpenAI Service Error: $e');
      return _getErrorResponse();
    }
  }

  String _getDemoResponse(String message) {
    // Demo responses for when API key is not configured
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('bitcoin') || lowerMessage.contains('btc')) {
      return "🪙 Bitcoin (BTC) is the first and largest cryptocurrency by market cap. It's often called 'digital gold' and serves as a store of value. Current trends show institutional adoption is growing!";
    } else if (lowerMessage.contains('ethereum') || lowerMessage.contains('eth')) {
      return "⚡ Ethereum (ETH) is a decentralized platform that enables smart contracts and DApps. It's the foundation for most DeFi protocols and NFT marketplaces. The transition to Proof-of-Stake has made it more energy efficient!";
    } else if (lowerMessage.contains('defi')) {
      return "🏦 DeFi (Decentralized Finance) allows you to lend, borrow, trade, and earn yield without traditional banks. Popular protocols include Uniswap, Compound, and Aave. Always research before investing!";
    } else if (lowerMessage.contains('nft')) {
      return "🖼️ NFTs (Non-Fungible Tokens) are unique digital assets on the blockchain. They're popular for digital art, gaming items, and collectibles. The market is evolving beyond just profile pictures!";
    } else if (lowerMessage.contains('trading') || lowerMessage.contains('trade')) {
      return "📈 Crypto trading involves buying and selling digital assets. Key tips: Do your research (DYOR), never invest more than you can afford to lose, and consider dollar-cost averaging for long-term positions.";
    } else if (lowerMessage.contains('wallet')) {
      return "🔐 Crypto wallets store your private keys and let you interact with blockchains. Hardware wallets (cold storage) are most secure for large amounts. Always backup your seed phrase safely!";
    } else if (lowerMessage.contains('mining')) {
      return "⛏️ Cryptocurrency mining secures networks and validates transactions. Bitcoin uses Proof-of-Work mining, while newer chains like Ethereum use more energy-efficient Proof-of-Stake consensus.";
    } else {
      return "🤖 I'm CNETV AI! I can help with questions about cryptocurrencies, blockchain technology, DeFi, NFTs, trading strategies, and more. What would you like to learn about?";
    }
  }

  String _getErrorResponse() {
    return "Sorry, I'm having trouble connecting right now. Please try again later. In the meantime, feel free to ask about Bitcoin, Ethereum, DeFi, or other crypto topics!";
  }
}