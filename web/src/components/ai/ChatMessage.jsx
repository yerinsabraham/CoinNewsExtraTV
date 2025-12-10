import React from 'react';
import { Bot, User } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

const ChatMessage = ({ message, isUser }) => {
  const timestamp = message.timestamp ? new Date(message.timestamp) : new Date();

  return (
    <div className={`flex gap-3 mb-4 ${isUser ? 'flex-row-reverse' : 'flex-row'}`}>
      {/* Avatar */}
      <div className={`
        flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center
        ${isUser ? 'bg-blue-600' : 'bg-purple-600'}
      `}>
        {isUser ? (
          <User className="w-5 h-5 text-white" />
        ) : (
          <Bot className="w-5 h-5 text-white" />
        )}
      </div>

      {/* Message Bubble */}
      <div className={`flex-1 max-w-[70%]`}>
        <div className={`
          rounded-2xl px-4 py-3
          ${isUser 
            ? 'bg-blue-600 text-white rounded-tr-none' 
            : 'bg-gray-800 text-gray-100 rounded-tl-none'
          }
        `}>
          <p className="whitespace-pre-wrap break-words leading-relaxed">
            {message.content}
          </p>
        </div>
        
        {/* Timestamp */}
        <p className={`text-xs text-gray-500 mt-1 ${isUser ? 'text-right' : 'text-left'}`}>
          {formatDistanceToNow(timestamp, { addSuffix: true })}
        </p>
      </div>
    </div>
  );
};

export default ChatMessage;
