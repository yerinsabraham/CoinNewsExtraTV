import React from 'react';
import { MessageSquare, Coins } from 'lucide-react';

/**
 * ChatStats Component
 * Displays chat statistics
 */
const ChatStats = ({ stats = {} }) => {
  const { totalMessages = 0, totalEarned = 0 } = stats;
  
  return (
    <div className="grid grid-cols-2 gap-4">
      <div className="bg-dark-card rounded-lg p-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-lg bg-blue-500/10 flex items-center justify-center">
            <MessageSquare className="w-6 h-6 text-blue-400" />
          </div>
          <div>
            <p className="text-sm text-gray-400">Messages Sent</p>
            <p className="text-2xl font-bold text-blue-400">{totalMessages.toLocaleString()}</p>
          </div>
        </div>
      </div>
      
      <div className="bg-dark-card rounded-lg p-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-lg bg-green-500/10 flex items-center justify-center">
            <Coins className="w-6 h-6 text-green-400" />
          </div>
          <div>
            <p className="text-sm text-gray-400">Earned from Chat</p>
            <p className="text-2xl font-bold text-green-400">{totalEarned.toFixed(1)} CNE</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ChatStats;
