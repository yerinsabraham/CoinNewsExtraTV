import React, { useState } from 'react';
import { Send, Loader2 } from 'lucide-react';

/**
 * MessageInput Component
 * Input field for sending messages
 */
const MessageInput = ({ onSend, disabled = false, placeholder = "Type a message..." }) => {
  const [message, setMessage] = useState('');
  const [sending, setSending] = useState(false);
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!message.trim() || sending || disabled) return;
    
    setSending(true);
    
    try {
      await onSend(message);
      setMessage('');
    } catch (error) {
      console.error('Error sending message:', error);
    } finally {
      setSending(false);
    }
  };
  
  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };
  
  return (
    <form onSubmit={handleSubmit} className="flex items-center gap-3">
      <input
        type="text"
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        onKeyPress={handleKeyPress}
        placeholder={placeholder}
        disabled={disabled || sending}
        className="flex-1 bg-dark-card border border-dark-border rounded-full px-6 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent disabled:opacity-50 disabled:cursor-not-allowed"
        maxLength={500}
      />
      
      <button
        type="submit"
        disabled={!message.trim() || disabled || sending}
        className="flex-shrink-0 w-12 h-12 bg-primary hover:bg-primary/90 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded-full flex items-center justify-center transition-colors shadow-lg hover:shadow-xl"
      >
        {sending ? (
          <Loader2 className="w-5 h-5 animate-spin" />
        ) : (
          <Send className="w-5 h-5" />
        )}
      </button>
    </form>
  );
};

export default MessageInput;
