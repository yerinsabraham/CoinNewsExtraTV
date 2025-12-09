import React from 'react';
import { formatDistanceToNow } from 'date-fns';
import { Trash2 } from 'lucide-react';

/**
 * MessageBubble Component
 * Displays a single chat message
 */
const MessageBubble = ({ message, currentUserId, onDelete }) => {
  const isOwnMessage = message.userId === currentUserId;
  const timestamp = message.createdAt || message.timestamp;
  const timeAgo = timestamp ? formatDistanceToNow(new Date(timestamp), { addSuffix: true }) : 'Just now';
  
  return (
    <div className={`flex gap-3 mb-4 ${isOwnMessage ? 'flex-row-reverse' : 'flex-row'}`}>
      {/* User Avatar */}
      <div className="flex-shrink-0">
        {message.userPhoto ? (
          <img
            src={message.userPhoto}
            alt={message.userName}
            className="w-10 h-10 rounded-full object-cover"
          />
        ) : (
          <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center text-white font-bold">
            {message.userName?.[0]?.toUpperCase() || '?'}
          </div>
        )}
      </div>
      
      {/* Message Content */}
      <div className={`flex flex-col max-w-[70%] ${isOwnMessage ? 'items-end' : 'items-start'}`}>
        {/* User Name and Time */}
        <div className={`flex items-center gap-2 mb-1 ${isOwnMessage ? 'flex-row-reverse' : 'flex-row'}`}>
          <span className="text-sm font-semibold text-gray-300">
            {isOwnMessage ? 'You' : message.userName}
          </span>
          <span className="text-xs text-gray-500">
            {timeAgo}
          </span>
        </div>
        
        {/* Message Bubble */}
        <div className={`relative group ${isOwnMessage ? 'items-end' : 'items-start'} flex`}>
          <div
            className={`
              px-4 py-2 rounded-2xl break-words
              ${isOwnMessage
                ? 'bg-primary text-white rounded-br-sm'
                : 'bg-dark-card text-white rounded-bl-sm'
              }
            `}
          >
            <p className="text-sm whitespace-pre-wrap">{message.message}</p>
          </div>
          
          {/* Delete Button (only for own messages) */}
          {isOwnMessage && onDelete && (
            <button
              onClick={() => onDelete(message.id)}
              className="ml-2 opacity-0 group-hover:opacity-100 transition-opacity p-1 hover:bg-red-500/20 rounded"
              title="Delete message"
            >
              <Trash2 className="w-4 h-4 text-red-400" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default MessageBubble;
