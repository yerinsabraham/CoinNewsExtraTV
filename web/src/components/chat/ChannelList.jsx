import React from 'react';
import { Hash, Users } from 'lucide-react';

/**
 * ChannelList Component
 * Displays list of available chat channels
 */
const ChannelList = ({ channels, activeChannelId, onChannelSelect, onlineCounts = {} }) => {
  return (
    <div className="bg-dark-card rounded-lg p-4">
      <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
        <Hash className="w-5 h-5" />
        Channels
      </h3>
      
      <div className="space-y-2">
        {channels.map((channel) => {
          const isActive = channel.id === activeChannelId;
          const onlineCount = onlineCounts[channel.id] || 0;
          
          return (
            <button
              key={channel.id}
              onClick={() => onChannelSelect(channel.id)}
              className={`
                w-full text-left px-4 py-3 rounded-lg transition-all
                flex items-center justify-between group
                ${isActive
                  ? 'bg-primary text-white shadow-lg'
                  : 'bg-dark-bg hover:bg-dark-bg/80 text-gray-300 hover:text-white'
                }
              `}
            >
              <div className="flex items-center gap-3 flex-1 min-w-0">
                <span className="text-2xl flex-shrink-0">{channel.icon}</span>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold truncate">{channel.name}</p>
                  <p className={`text-xs truncate ${isActive ? 'text-white/80' : 'text-gray-500'}`}>
                    {channel.description}
                  </p>
                </div>
              </div>
              
              {onlineCount > 0 && (
                <div className={`
                  flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold flex-shrink-0 ml-2
                  ${isActive ? 'bg-white/20' : 'bg-green-500/20 text-green-400'}
                `}>
                  <Users className="w-3 h-3" />
                  <span>{onlineCount}</span>
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default ChannelList;
