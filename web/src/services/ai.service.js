import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase';

/**
 * AI Assistant Service
 * Handles communication with OpenAI through Firebase Functions
 */

// Conversation context types
export const CONTEXT_TYPES = {
  GENERAL: 'general',
  CRYPTO_NEWS: 'crypto_news',
  PLATFORM_HELP: 'platform_help',
  EARNINGS_TIPS: 'earnings_tips'
};

// Message roles
export const MESSAGE_ROLES = {
  USER: 'user',
  ASSISTANT: 'assistant',
  SYSTEM: 'system'
};

/**
 * Send message to AI assistant
 */
export const sendMessageToAI = async (message, conversationHistory = [], contextType = CONTEXT_TYPES.GENERAL) => {
  try {
    // Call Firebase Function
    const askAI = httpsCallable(functions, 'askOpenAI');
    
    const response = await askAI({
      message,
      conversationHistory,
      contextType
    });

    return {
      success: true,
      message: response.data.message,
      usage: response.data.usage
    };
  } catch (error) {
    console.error('Error calling AI assistant:', error);
    
    // Fallback responses for common queries
    if (message.toLowerCase().includes('how to earn')) {
      return {
        success: true,
        message: "You can earn CNE through multiple ways:\n\n1. **Watch Videos** (7 CNE per video)\n2. **Complete Quizzes** (2 CNE per correct answer)\n3. **Spin the Wheel** (10-1000 CNE daily)\n4. **Daily Check-ins** (28 CNE + streak bonuses)\n5. **Chat with Community** (0.1 CNE per message)\n6. **Refer Friends** (100 CNE per referral)\n\nStart with daily check-ins and watching videos for steady earnings!",
        fallback: true
      };
    }
    
    if (message.toLowerCase().includes('referral')) {
      return {
        success: true,
        message: "Our referral program rewards both you and your friends!\n\n**Referrer Bonus:** 100 CNE\n**Referee Bonus:** 50 CNE\n\nShare your unique referral code from the Referrals page and earn CNE every time someone signs up using your code.",
        fallback: true
      };
    }

    if (message.toLowerCase().includes('leaderboard')) {
      return {
        success: true,
        message: "The leaderboard shows top earners on our platform! You can view rankings by:\n\n- Daily\n- Weekly\n- Monthly\n- All-Time\n\nYour rank is based on total earnings from all activities. Keep earning to climb the leaderboard!",
        fallback: true
      };
    }

    return {
      success: false,
      error: error.message || 'Failed to get AI response'
    };
  }
};

/**
 * Get context-specific system prompt
 */
export const getSystemPrompt = (contextType) => {
  const prompts = {
    [CONTEXT_TYPES.GENERAL]: "You are a helpful assistant for CoinNewsExtra Watch2Earn platform. Help users with questions about earning CNE tokens, using features, and general platform support.",
    
    [CONTEXT_TYPES.CRYPTO_NEWS]: "You are a cryptocurrency news expert. Provide accurate, up-to-date information about crypto markets, trends, and news. Keep responses concise and informative.",
    
    [CONTEXT_TYPES.PLATFORM_HELP]: "You are a support agent for CoinNewsExtra Watch2Earn platform. Help users troubleshoot issues, understand features, and maximize their earnings. Be friendly and solution-oriented.",
    
    [CONTEXT_TYPES.EARNINGS_TIPS]: "You are an earnings optimization expert. Provide tips and strategies for maximizing CNE earnings through videos, quizzes, spins, check-ins, referrals, and chat participation."
  };

  return prompts[contextType] || prompts[CONTEXT_TYPES.GENERAL];
};

/**
 * Format conversation for display
 */
export const formatConversation = (messages) => {
  return messages.map(msg => ({
    role: msg.role,
    content: msg.content,
    timestamp: msg.timestamp || new Date().toISOString()
  }));
};

/**
 * Get suggested questions based on context
 */
export const getSuggestedQuestions = (contextType) => {
  const suggestions = {
    [CONTEXT_TYPES.GENERAL]: [
      "How do I earn CNE?",
      "What features are available?",
      "How does the referral program work?",
      "What is the daily check-in bonus?"
    ],
    
    [CONTEXT_TYPES.CRYPTO_NEWS]: [
      "What's trending in crypto today?",
      "Tell me about Bitcoin's recent performance",
      "What are the top altcoins?",
      "Latest crypto market news"
    ],
    
    [CONTEXT_TYPES.PLATFORM_HELP]: [
      "How do I watch videos?",
      "Why didn't I receive my reward?",
      "How do I refer friends?",
      "How does the spin wheel work?"
    ],
    
    [CONTEXT_TYPES.EARNINGS_TIPS]: [
      "How can I maximize my daily earnings?",
      "What's the fastest way to earn CNE?",
      "How do streak bonuses work?",
      "Should I focus on videos or quizzes?"
    ]
  };

  return suggestions[contextType] || suggestions[CONTEXT_TYPES.GENERAL];
};

/**
 * Validate message before sending
 */
export const validateMessage = (message) => {
  if (!message || message.trim().length === 0) {
    return { valid: false, error: 'Message cannot be empty' };
  }

  if (message.length > 1000) {
    return { valid: false, error: 'Message too long (max 1000 characters)' };
  }

  // Check for spam patterns
  const spamPatterns = [
    /(.)\1{10,}/, // Repeated characters
    /^[A-Z\s!]+$/, // All caps
  ];

  for (const pattern of spamPatterns) {
    if (pattern.test(message)) {
      return { valid: false, error: 'Message appears to be spam' };
    }
  }

  return { valid: true };
};

/**
 * Save conversation to localStorage
 */
export const saveConversation = (conversationId, messages) => {
  try {
    const conversations = JSON.parse(localStorage.getItem('ai_conversations') || '{}');
    conversations[conversationId] = {
      messages,
      lastUpdated: new Date().toISOString()
    };
    localStorage.setItem('ai_conversations', JSON.stringify(conversations));
    return true;
  } catch (error) {
    console.error('Error saving conversation:', error);
    return false;
  }
};

/**
 * Load conversation from localStorage
 */
export const loadConversation = (conversationId) => {
  try {
    const conversations = JSON.parse(localStorage.getItem('ai_conversations') || '{}');
    return conversations[conversationId]?.messages || [];
  } catch (error) {
    console.error('Error loading conversation:', error);
    return [];
  }
};

/**
 * Clear conversation history
 */
export const clearConversation = (conversationId) => {
  try {
    const conversations = JSON.parse(localStorage.getItem('ai_conversations') || '{}');
    delete conversations[conversationId];
    localStorage.setItem('ai_conversations', JSON.stringify(conversations));
    return true;
  } catch (error) {
    console.error('Error clearing conversation:', error);
    return false;
  }
};
