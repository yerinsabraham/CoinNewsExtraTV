import { rtdb, db } from './firebase';
import { 
  ref, 
  push, 
  set, 
  onValue, 
  query, 
  orderByChild, 
  limitToLast,
  get,
  update,
  serverTimestamp as rtdbServerTimestamp
} from 'firebase/database';
import { 
  doc, 
  updateDoc, 
  increment,
  serverTimestamp,
  getDoc,
  setDoc,
  collection
} from 'firebase/firestore';

/**
 * Chat Service
 * Manages real-time messaging with Firebase Realtime Database
 */

const MESSAGE_REWARD = 0.1; // CNE per message
const MAX_MESSAGES_PER_LOAD = 50;

// Available channels
export const CHANNELS = [
  { id: 'general', name: 'General', description: 'General discussion', icon: '💬' },
  { id: 'crypto', name: 'Crypto Talk', description: 'Discuss cryptocurrencies', icon: '₿' },
  { id: 'trading', name: 'Trading', description: 'Trading strategies and tips', icon: '📈' },
  { id: 'news', name: 'News', description: 'Latest crypto news', icon: '📰' },
  { id: 'support', name: 'Support', description: 'Get help and support', icon: '🆘' }
];

/**
 * Send a message to a channel
 */
export async function sendMessage(userId, channelId, message, userDisplayName, userPhotoURL) {
  try {
    if (!message || !message.trim()) {
      throw new Error('Message cannot be empty');
    }
    
    // Create message object
    const messageData = {
      userId,
      userName: userDisplayName || 'Anonymous',
      userPhoto: userPhotoURL || null,
      message: message.trim(),
      timestamp: rtdbServerTimestamp(),
      createdAt: Date.now()
    };
    
    // Push message to Realtime Database
    const messagesRef = ref(rtdb, `channels/${channelId}/messages`);
    const newMessageRef = push(messagesRef);
    await set(newMessageRef, messageData);
    
    // Award CNE for sending message
    await awardMessageReward(userId);
    
    // Update user's last message timestamp
    const userRef = ref(rtdb, `users/${userId}/lastMessage`);
    await set(userRef, Date.now());
    
    return {
      success: true,
      messageId: newMessageRef.key,
      reward: MESSAGE_REWARD
    };
  } catch (error) {
    console.error('Error sending message:', error);
    throw error;
  }
}

/**
 * Award CNE for sending a message
 */
async function awardMessageReward(userId) {
  try {
    // Get user document
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    
    if (!userDoc.exists()) {
      throw new Error('User not found');
    }
    
    const userData = userDoc.data();
    const currentBalance = userData.cneBalance || 0;
    const newBalance = currentBalance + MESSAGE_REWARD;
    
    // Update user balance
    await updateDoc(userRef, {
      cneBalance: newBalance,
      totalBalance: newBalance,
      unlockedBalance: newBalance,
      totalEarnings: increment(MESSAGE_REWARD),
      'earnings.chat': increment(MESSAGE_REWARD),
      lastUpdated: new Date().toISOString(),
      updatedAt: serverTimestamp()
    });
    
    // Log transaction
    const transactionRef = collection(db, 'users', userId, 'transactions');
    await setDoc(doc(transactionRef), {
      type: 'chat_message',
      amount: MESSAGE_REWARD,
      description: 'Chat message reward',
      oldBalance: currentBalance,
      newBalance,
      status: 'completed',
      timestamp: serverTimestamp(),
      createdAt: serverTimestamp()
    });
  } catch (error) {
    console.error('Error awarding message reward:', error);
    // Don't throw error - message was sent successfully
  }
}

/**
 * Subscribe to messages in a channel
 */
export function subscribeToMessages(channelId, callback, limit = MAX_MESSAGES_PER_LOAD) {
  const messagesRef = ref(rtdb, `channels/${channelId}/messages`);
  const messagesQuery = query(
    messagesRef,
    orderByChild('createdAt'),
    limitToLast(limit)
  );
  
  const unsubscribe = onValue(messagesQuery, (snapshot) => {
    const messages = [];
    snapshot.forEach((childSnapshot) => {
      messages.push({
        id: childSnapshot.key,
        ...childSnapshot.val()
      });
    });
    
    // Sort by timestamp
    messages.sort((a, b) => (a.createdAt || 0) - (b.createdAt || 0));
    
    callback(messages);
  });
  
  return unsubscribe;
}

/**
 * Get message count for a channel
 */
export async function getChannelMessageCount(channelId) {
  try {
    const messagesRef = ref(rtdb, `channels/${channelId}/messages`);
    const snapshot = await get(messagesRef);
    
    if (!snapshot.exists()) {
      return 0;
    }
    
    return snapshot.size;
  } catch (error) {
    console.error('Error getting message count:', error);
    return 0;
  }
}

/**
 * Get user's chat statistics
 */
export async function getUserChatStats(userId) {
  try {
    const userStatsRef = ref(rtdb, `userStats/${userId}`);
    const snapshot = await get(userStatsRef);
    
    if (!snapshot.exists()) {
      return {
        totalMessages: 0,
        totalEarned: 0
      };
    }
    
    const data = snapshot.val();
    return {
      totalMessages: data.totalMessages || 0,
      totalEarned: (data.totalMessages || 0) * MESSAGE_REWARD
    };
  } catch (error) {
    console.error('Error getting user chat stats:', error);
    return {
      totalMessages: 0,
      totalEarned: 0
    };
  }
}

/**
 * Update user stats after sending message
 */
export async function updateUserChatStats(userId) {
  try {
    const userStatsRef = ref(rtdb, `userStats/${userId}`);
    const snapshot = await get(userStatsRef);
    
    let currentMessages = 0;
    if (snapshot.exists()) {
      currentMessages = snapshot.val().totalMessages || 0;
    }
    
    await update(userStatsRef, {
      totalMessages: currentMessages + 1,
      lastMessageAt: Date.now()
    });
  } catch (error) {
    console.error('Error updating user stats:', error);
  }
}

/**
 * Get all channels
 */
export function getChannels() {
  return CHANNELS;
}

/**
 * Get channel by ID
 */
export function getChannelById(channelId) {
  return CHANNELS.find(channel => channel.id === channelId);
}

/**
 * Delete a message (only if user is message author)
 */
export async function deleteMessage(userId, channelId, messageId, messageUserId) {
  try {
    // Check if user is the message author
    if (userId !== messageUserId) {
      throw new Error('You can only delete your own messages');
    }
    
    const messageRef = ref(rtdb, `channels/${channelId}/messages/${messageId}`);
    await set(messageRef, null);
    
    return { success: true };
  } catch (error) {
    console.error('Error deleting message:', error);
    throw error;
  }
}

/**
 * Get message reward amount
 */
export function getMessageReward() {
  return MESSAGE_REWARD;
}

/**
 * Check if user can send messages (rate limiting)
 */
export async function canSendMessage(userId) {
  try {
    const userRef = ref(rtdb, `users/${userId}/lastMessage`);
    const snapshot = await get(userRef);
    
    if (!snapshot.exists()) {
      return true;
    }
    
    const lastMessageTime = snapshot.val();
    const now = Date.now();
    const timeSinceLastMessage = now - lastMessageTime;
    
    // Require at least 1 second between messages
    return timeSinceLastMessage >= 1000;
  } catch (error) {
    console.error('Error checking send permission:', error);
    return true; // Allow on error
  }
}

/**
 * Get online users count for a channel
 */
export function subscribeToOnlineUsers(channelId, callback) {
  const onlineRef = ref(rtdb, `channels/${channelId}/online`);
  
  const unsubscribe = onValue(onlineRef, (snapshot) => {
    if (!snapshot.exists()) {
      callback(0);
      return;
    }
    
    callback(snapshot.size);
  });
  
  return unsubscribe;
}

/**
 * Mark user as online in a channel
 */
export async function markUserOnline(userId, channelId, userDisplayName) {
  try {
    const onlineRef = ref(rtdb, `channels/${channelId}/online/${userId}`);
    await set(onlineRef, {
      userName: userDisplayName || 'Anonymous',
      timestamp: rtdbServerTimestamp()
    });
  } catch (error) {
    console.error('Error marking user online:', error);
  }
}

/**
 * Mark user as offline in a channel
 */
export async function markUserOffline(userId, channelId) {
  try {
    const onlineRef = ref(rtdb, `channels/${channelId}/online/${userId}`);
    await set(onlineRef, null);
  } catch (error) {
    console.error('Error marking user offline:', error);
  }
}
