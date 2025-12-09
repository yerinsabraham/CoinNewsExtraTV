import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import {
  getChannels,
  getChannelById,
  subscribeToMessages,
  sendMessage,
  deleteMessage,
  getUserChatStats,
  updateUserChatStats,
  getMessageReward,
  markUserOnline,
  markUserOffline,
  subscribeToOnlineUsers
} from '../../services/chat.service';
import ChannelList from '../../components/chat/ChannelList';
import MessageBubble from '../../components/chat/MessageBubble';
import MessageInput from '../../components/chat/MessageInput';
import ChatStats from '../../components/chat/ChatStats';
import { ArrowLeft, Hash, Info, Coins } from 'lucide-react';
import toast from 'react-hot-toast';

/**
 * ChatPage - Real-time Chat System
 * Chat with other users and earn 0.1 CNE per message
 */
const ChatPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [channels] = useState(getChannels());
  const [activeChannelId, setActiveChannelId] = useState('general');
  const [messages, setMessages] = useState([]);
  const [stats, setStats] = useState({});
  const [onlineCounts, setOnlineCounts] = useState({});
  const [loading, setLoading] = useState(true);
  
  const messagesEndRef = useRef(null);
  const unsubscribeRef = useRef(null);
  const onlineUnsubscribesRef = useRef({});
  
  const messageReward = getMessageReward();
  const activeChannel = getChannelById(activeChannelId);
  
  // Load user stats
  useEffect(() => {
    if (user) {
      loadUserStats();
    }
  }, [user]);
  
  // Subscribe to messages when channel changes
  useEffect(() => {
    if (user && activeChannelId) {
      setLoading(true);
      
      // Unsubscribe from previous channel
      if (unsubscribeRef.current) {
        unsubscribeRef.current();
      }
      
      // Mark user as offline in previous channel
      const previousChannelId = sessionStorage.getItem('lastChannelId');
      if (previousChannelId && previousChannelId !== activeChannelId) {
        markUserOffline(user.uid, previousChannelId);
      }
      
      // Subscribe to new channel
      const unsubscribe = subscribeToMessages(activeChannelId, (newMessages) => {
        setMessages(newMessages);
        setLoading(false);
        scrollToBottom();
      });
      
      unsubscribeRef.current = unsubscribe;
      
      // Mark user as online in new channel
      markUserOnline(user.uid, activeChannelId, user.displayName);
      sessionStorage.setItem('lastChannelId', activeChannelId);
      
      return () => {
        if (unsubscribe) {
          unsubscribe();
        }
        markUserOffline(user.uid, activeChannelId);
      };
    }
  }, [user, activeChannelId]);
  
  // Subscribe to online users for all channels
  useEffect(() => {
    if (user) {
      channels.forEach((channel) => {
        const unsubscribe = subscribeToOnlineUsers(channel.id, (count) => {
          setOnlineCounts(prev => ({
            ...prev,
            [channel.id]: count
          }));
        });
        
        onlineUnsubscribesRef.current[channel.id] = unsubscribe;
      });
      
      return () => {
        Object.values(onlineUnsubscribesRef.current).forEach(unsubscribe => {
          if (unsubscribe) unsubscribe();
        });
      };
    }
  }, [user, channels]);
  
  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    scrollToBottom();
  }, [messages]);
  
  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (user && activeChannelId) {
        markUserOffline(user.uid, activeChannelId);
      }
    };
  }, [user, activeChannelId]);
  
  const loadUserStats = async () => {
    try {
      const userStats = await getUserChatStats(user.uid);
      setStats(userStats);
    } catch (error) {
      console.error('Error loading user stats:', error);
    }
  };
  
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };
  
  const handleSendMessage = async (message) => {
    if (!user || !message.trim()) return;
    
    try {
      const result = await sendMessage(
        user.uid,
        activeChannelId,
        message,
        user.displayName,
        user.photoURL
      );
      
      // Update user stats
      await updateUserChatStats(user.uid);
      
      // Reload stats
      await loadUserStats();
      
      // Show reward notification
      toast.success(`+${result.reward} CNE`, {
        icon: '💰',
        duration: 2000
      });
    } catch (error) {
      console.error('Error sending message:', error);
      toast.error(error.message || 'Failed to send message');
      throw error;
    }
  };
  
  const handleDeleteMessage = async (messageId) => {
    if (!user) return;
    
    const message = messages.find(m => m.id === messageId);
    if (!message) return;
    
    try {
      await deleteMessage(user.uid, activeChannelId, messageId, message.userId);
      toast.success('Message deleted');
    } catch (error) {
      console.error('Error deleting message:', error);
      toast.error(error.message || 'Failed to delete message');
    }
  };
  
  const handleChannelSelect = (channelId) => {
    setActiveChannelId(channelId);
    setMessages([]);
  };
  
  return (
    <div className="min-h-screen bg-dark-bg">
      {/* Header */}
      <div className="bg-gradient-to-r from-primary to-green-600 text-white p-6">
        <div className="max-w-7xl mx-auto">
          <button
            onClick={() => navigate('/')}
            className="flex items-center gap-2 text-white/90 hover:text-white mb-4 transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Back to Home
          </button>
          
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold flex items-center gap-3">
                <Hash className="w-8 h-8" />
                Chat
              </h1>
              <p className="text-white/90 mt-2">
                Chat with the community and earn {messageReward} CNE per message
              </p>
            </div>
          </div>
        </div>
      </div>
      
      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Info Banner */}
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4 mb-6 flex items-start gap-3">
          <Info className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
          <div className="text-sm text-gray-300">
            <p className="font-semibold text-white mb-1">How it works:</p>
            <ul className="list-disc list-inside space-y-1 text-gray-400">
              <li>Earn {messageReward} CNE for every message you send</li>
              <li>Choose from different channels for various topics</li>
              <li>Be respectful and follow community guidelines</li>
              <li>Have fun and engage with the community!</li>
            </ul>
          </div>
        </div>
        
        {/* Stats */}
        <div className="mb-6">
          <ChatStats stats={stats} />
        </div>
        
        {/* Chat Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          {/* Channels Sidebar */}
          <div className="lg:col-span-1">
            <ChannelList
              channels={channels}
              activeChannelId={activeChannelId}
              onChannelSelect={handleChannelSelect}
              onlineCounts={onlineCounts}
            />
          </div>
          
          {/* Chat Area */}
          <div className="lg:col-span-3">
            <div className="bg-dark-card rounded-lg flex flex-col h-[600px]">
              {/* Channel Header */}
              <div className="p-4 border-b border-dark-border flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="text-3xl">{activeChannel?.icon}</span>
                  <div>
                    <h3 className="text-xl font-bold text-white">{activeChannel?.name}</h3>
                    <p className="text-sm text-gray-400">{activeChannel?.description}</p>
                  </div>
                </div>
                
                <div className="flex items-center gap-2 text-sm">
                  <Coins className="w-4 h-4 text-green-400" />
                  <span className="text-gray-400">
                    +{messageReward} CNE per message
                  </span>
                </div>
              </div>
              
              {/* Messages */}
              <div className="flex-1 overflow-y-auto p-4 custom-scrollbar">
                {loading ? (
                  <div className="flex items-center justify-center h-full">
                    <div className="text-center">
                      <div className="animate-spin w-12 h-12 border-4 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
                      <p className="text-gray-400">Loading messages...</p>
                    </div>
                  </div>
                ) : messages.length === 0 ? (
                  <div className="flex items-center justify-center h-full">
                    <div className="text-center">
                      <Hash className="w-16 h-16 text-gray-600 mx-auto mb-4" />
                      <p className="text-gray-400 text-lg mb-2">No messages yet</p>
                      <p className="text-gray-500 text-sm">Be the first to start the conversation!</p>
                    </div>
                  </div>
                ) : (
                  <>
                    {messages.map((message) => (
                      <MessageBubble
                        key={message.id}
                        message={message}
                        currentUserId={user?.uid}
                        onDelete={handleDeleteMessage}
                      />
                    ))}
                    <div ref={messagesEndRef} />
                  </>
                )}
              </div>
              
              {/* Message Input */}
              <div className="p-4 border-t border-dark-border">
                <MessageInput
                  onSend={handleSendMessage}
                  placeholder={`Message #${activeChannel?.name.toLowerCase()}...`}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ChatPage;
