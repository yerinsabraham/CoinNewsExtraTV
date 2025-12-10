import React, { useState, useEffect, useRef } from 'react';
import { Bot, Send, Trash2, AlertCircle } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { 
  sendMessageToAI, 
  getSuggestedQuestions, 
  validateMessage,
  saveConversation,
  loadConversation,
  clearConversation,
  MESSAGE_ROLES,
  CONTEXT_TYPES
} from '../../services/ai.service';
import ChatMessage from '../../components/ai/ChatMessage';
import SuggestedQuestions from '../../components/ai/SuggestedQuestions';
import ContextSelector from '../../components/ai/ContextSelector';
import { toast } from 'react-hot-toast';

const AIAssistantPage = () => {
  const { user } = useAuth();
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [contextType, setContextType] = useState(CONTEXT_TYPES.GENERAL);
  const [suggestedQuestions, setSuggestedQuestions] = useState([]);
  const messagesEndRef = useRef(null);
  const conversationId = `ai_chat_${user?.uid}`;

  // Load conversation on mount
  useEffect(() => {
    const savedMessages = loadConversation(conversationId);
    if (savedMessages.length > 0) {
      setMessages(savedMessages);
    } else {
      // Welcome message
      setMessages([{
        role: MESSAGE_ROLES.ASSISTANT,
        content: "👋 Hello! I'm your AI assistant for CoinNewsExtra. I can help you with:\n\n• Platform features and how to use them\n• Earning strategies and tips\n• Crypto news and market updates\n• Technical support\n\nHow can I assist you today?",
        timestamp: new Date().toISOString()
      }]);
    }
  }, [conversationId]);

  // Update suggested questions when context changes
  useEffect(() => {
    setSuggestedQuestions(getSuggestedQuestions(contextType));
  }, [contextType]);

  // Auto-scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Save conversation when messages change
  useEffect(() => {
    if (messages.length > 1) { // Don't save just welcome message
      saveConversation(conversationId, messages);
    }
  }, [messages, conversationId]);

  const handleSendMessage = async (messageText = inputMessage) => {
    const validation = validateMessage(messageText);
    if (!validation.valid) {
      toast.error(validation.error);
      return;
    }

    // Add user message
    const userMessage = {
      role: MESSAGE_ROLES.USER,
      content: messageText,
      timestamp: new Date().toISOString()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputMessage('');
    setLoading(true);

    try {
      // Get conversation history (last 10 messages for context)
      const conversationHistory = messages.slice(-10).map(msg => ({
        role: msg.role,
        content: msg.content
      }));

      // Send to AI
      const response = await sendMessageToAI(messageText, conversationHistory, contextType);

      if (response.success) {
        const assistantMessage = {
          role: MESSAGE_ROLES.ASSISTANT,
          content: response.message,
          timestamp: new Date().toISOString(),
          fallback: response.fallback || false
        };

        setMessages(prev => [...prev, assistantMessage]);

        if (response.fallback) {
          toast('Using fallback response', { icon: '⚠️' });
        }
      } else {
        throw new Error(response.error || 'Failed to get response');
      }
    } catch (error) {
      console.error('Error sending message:', error);
      toast.error('Failed to get AI response. Please try again.');
      
      // Add error message
      setMessages(prev => [...prev, {
        role: MESSAGE_ROLES.ASSISTANT,
        content: "I'm sorry, I'm having trouble processing your request right now. Please try again or contact support if the issue persists.",
        timestamp: new Date().toISOString(),
        error: true
      }]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const handleClearChat = () => {
    if (window.confirm('Are you sure you want to clear the chat history?')) {
      clearConversation(conversationId);
      setMessages([{
        role: MESSAGE_ROLES.ASSISTANT,
        content: "Chat history cleared. How can I help you?",
        timestamp: new Date().toISOString()
      }]);
      toast.success('Chat history cleared');
    }
  };

  const handleSuggestedQuestionClick = (question) => {
    setInputMessage(question);
    handleSendMessage(question);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 py-8 px-4">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="bg-gradient-to-r from-purple-600 to-blue-600 rounded-2xl p-6 mb-6 shadow-xl">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="bg-white/20 p-3 rounded-xl">
                <Bot className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-white">AI Assistant</h1>
                <p className="text-blue-100">Powered by OpenAI</p>
              </div>
            </div>
            
            <button
              onClick={handleClearChat}
              className="bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-lg transition-all duration-200 flex items-center gap-2"
            >
              <Trash2 className="w-4 h-4" />
              <span className="hidden sm:inline">Clear Chat</span>
            </button>
          </div>
        </div>

        {/* Context Selector */}
        <ContextSelector
          selectedContext={contextType}
          onContextChange={setContextType}
          disabled={loading}
        />

        {/* Chat Messages */}
        <div className="bg-gray-800/50 backdrop-blur-sm rounded-2xl p-6 mb-4 shadow-xl">
          <div className="h-[500px] overflow-y-auto mb-4 pr-2 scrollbar-thin scrollbar-thumb-gray-700 scrollbar-track-gray-900">
            {messages.map((message, index) => (
              <ChatMessage
                key={index}
                message={message}
                isUser={message.role === MESSAGE_ROLES.USER}
              />
            ))}
            
            {loading && (
              <div className="flex gap-3 mb-4">
                <div className="flex-shrink-0 w-10 h-10 bg-purple-600 rounded-full flex items-center justify-center">
                  <Bot className="w-5 h-5 text-white animate-pulse" />
                </div>
                <div className="bg-gray-800 rounded-2xl rounded-tl-none px-4 py-3">
                  <div className="flex gap-2">
                    <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce"></div>
                    <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                    <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce" style={{ animationDelay: '0.4s' }}></div>
                  </div>
                </div>
              </div>
            )}
            
            <div ref={messagesEndRef} />
          </div>

          {/* Suggested Questions */}
          {messages.length <= 2 && (
            <SuggestedQuestions
              questions={suggestedQuestions}
              onQuestionClick={handleSuggestedQuestionClick}
              disabled={loading}
            />
          )}

          {/* Input Area */}
          <div className="flex gap-2">
            <input
              type="text"
              value={inputMessage}
              onChange={(e) => setInputMessage(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="Type your message..."
              disabled={loading}
              className="
                flex-1 bg-gray-900 text-white px-4 py-3 rounded-xl
                focus:outline-none focus:ring-2 focus:ring-purple-500
                disabled:opacity-50 disabled:cursor-not-allowed
              "
            />
            <button
              onClick={() => handleSendMessage()}
              disabled={loading || !inputMessage.trim()}
              className="
                bg-purple-600 hover:bg-purple-700 text-white px-6 py-3 rounded-xl
                transition-all duration-200 flex items-center gap-2
                disabled:opacity-50 disabled:cursor-not-allowed
                shadow-lg hover:shadow-purple-500/50
              "
            >
              <Send className="w-5 h-5" />
              <span className="hidden sm:inline">Send</span>
            </button>
          </div>

          {/* Info */}
          <div className="mt-3 flex items-start gap-2 text-xs text-gray-500">
            <AlertCircle className="w-4 h-4 flex-shrink-0 mt-0.5" />
            <p>
              AI responses may not always be accurate. For critical issues, please contact support.
            </p>
          </div>
        </div>

        {/* Feature Info */}
        <div className="bg-gray-800/30 rounded-xl p-4 text-center">
          <p className="text-sm text-gray-400">
            💡 <strong>Tip:</strong> Switch contexts above for specialized assistance with crypto news, earnings tips, or platform support!
          </p>
        </div>
      </div>
    </div>
  );
};

export default AIAssistantPage;
