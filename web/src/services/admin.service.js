import { 
  collection, 
  query, 
  getDocs, 
  doc, 
  updateDoc, 
  deleteDoc,
  where,
  orderBy,
  limit,
  getDoc,
  Timestamp,
  writeBatch
} from 'firebase/firestore';
import { db } from './firebase';

/**
 * Admin Service
 * Handles admin operations for platform management
 */

// Admin role check
export const isAdmin = async (userId) => {
  try {
    const userDoc = await getDoc(doc(db, 'users', userId));
    if (!userDoc.exists()) return false;
    
    const userData = userDoc.data();
    return userData.role === 'admin' || userData.isAdmin === true;
  } catch (error) {
    console.error('Error checking admin status:', error);
    return false;
  }
};

/**
 * Get platform statistics
 */
export const getPlatformStats = async () => {
  try {
    const usersSnapshot = await getDocs(collection(db, 'users'));
    const videosSnapshot = await getDocs(collection(db, 'videos'));
    const quizzesSnapshot = await getDocs(collection(db, 'quizzes'));
    const transactionsSnapshot = await getDocs(collection(db, 'transactions'));

    let totalCNEDistributed = 0;
    let totalCNEBalance = 0;
    let activeUsers = 0;
    const now = Date.now();
    const oneDayAgo = now - (24 * 60 * 60 * 1000);

    usersSnapshot.forEach(doc => {
      const user = doc.data();
      totalCNEBalance += user.balance || 0;
      
      // Check if user was active in last 24 hours
      const lastSignIn = user.lastSignIn?.toMillis?.() || 0;
      if (lastSignIn > oneDayAgo) {
        activeUsers++;
      }
    });

    transactionsSnapshot.forEach(doc => {
      const transaction = doc.data();
      if (transaction.amount > 0) {
        totalCNEDistributed += transaction.amount;
      }
    });

    return {
      totalUsers: usersSnapshot.size,
      activeUsers,
      totalVideos: videosSnapshot.size,
      totalQuizzes: quizzesSnapshot.size,
      totalTransactions: transactionsSnapshot.size,
      totalCNEDistributed,
      totalCNEBalance,
      lastUpdated: new Date().toISOString()
    };
  } catch (error) {
    console.error('Error fetching platform stats:', error);
    throw error;
  }
};

/**
 * Get all users with pagination
 */
export const getAllUsers = async (limitCount = 50) => {
  try {
    const usersRef = collection(db, 'users');
    const q = query(usersRef, orderBy('createdAt', 'desc'), limit(limitCount));
    const snapshot = await getDocs(q);

    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error fetching users:', error);
    throw error;
  }
};

/**
 * Update user balance (admin only)
 */
export const updateUserBalance = async (userId, newBalance, reason = 'Admin adjustment') => {
  try {
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    
    if (!userDoc.exists()) {
      throw new Error('User not found');
    }

    const oldBalance = userDoc.data().balance || 0;
    const difference = newBalance - oldBalance;

    // Update user balance
    await updateDoc(userRef, {
      balance: newBalance,
      lastModified: Timestamp.now()
    });

    // Create transaction record
    const transactionsRef = collection(db, 'transactions');
    const transactionDoc = doc(transactionsRef);
    await updateDoc(transactionDoc, {
      userId,
      type: 'admin_adjustment',
      amount: difference,
      oldBalance,
      newBalance,
      reason,
      timestamp: Timestamp.now()
    });

    return { success: true, oldBalance, newBalance };
  } catch (error) {
    console.error('Error updating user balance:', error);
    throw error;
  }
};

/**
 * Ban/Unban user
 */
export const toggleUserBan = async (userId, banned, reason = '') => {
  try {
    const userRef = doc(db, 'users', userId);
    await updateDoc(userRef, {
      banned,
      banReason: banned ? reason : null,
      bannedAt: banned ? Timestamp.now() : null,
      lastModified: Timestamp.now()
    });

    return { success: true, banned };
  } catch (error) {
    console.error('Error toggling user ban:', error);
    throw error;
  }
};

/**
 * Get all videos
 */
export const getAllVideos = async () => {
  try {
    const videosSnapshot = await getDocs(collection(db, 'videos'));
    return videosSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error fetching videos:', error);
    throw error;
  }
};

/**
 * Add new video
 */
export const addVideo = async (videoData) => {
  try {
    const videosRef = collection(db, 'videos');
    const newVideoDoc = doc(videosRef);
    
    await updateDoc(newVideoDoc, {
      ...videoData,
      createdAt: Timestamp.now(),
      views: 0,
      status: 'active'
    });

    return { success: true, id: newVideoDoc.id };
  } catch (error) {
    console.error('Error adding video:', error);
    throw error;
  }
};

/**
 * Update video
 */
export const updateVideo = async (videoId, updates) => {
  try {
    const videoRef = doc(db, 'videos', videoId);
    await updateDoc(videoRef, {
      ...updates,
      updatedAt: Timestamp.now()
    });

    return { success: true };
  } catch (error) {
    console.error('Error updating video:', error);
    throw error;
  }
};

/**
 * Delete video
 */
export const deleteVideo = async (videoId) => {
  try {
    await deleteDoc(doc(db, 'videos', videoId));
    return { success: true };
  } catch (error) {
    console.error('Error deleting video:', error);
    throw error;
  }
};

/**
 * Get all quizzes
 */
export const getAllQuizzes = async () => {
  try {
    const quizzesSnapshot = await getDocs(collection(db, 'quizzes'));
    return quizzesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error fetching quizzes:', error);
    throw error;
  }
};

/**
 * Get recent transactions
 */
export const getRecentTransactions = async (limitCount = 100) => {
  try {
    const transactionsRef = collection(db, 'transactions');
    const q = query(transactionsRef, orderBy('timestamp', 'desc'), limit(limitCount));
    const snapshot = await getDocs(q);

    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error fetching transactions:', error);
    throw error;
  }
};

/**
 * Get chat messages for moderation
 */
export const getChatMessages = async (channelId = 'general', limitCount = 50) => {
  try {
    // This would need to be implemented with Realtime Database
    // For now, return empty array
    return [];
  } catch (error) {
    console.error('Error fetching chat messages:', error);
    throw error;
  }
};

/**
 * Delete chat message (moderation)
 */
export const deleteChatMessage = async (messageId) => {
  try {
    // This would need to be implemented with Realtime Database
    return { success: true };
  } catch (error) {
    console.error('Error deleting chat message:', error);
    throw error;
  }
};

/**
 * Get system analytics
 */
export const getSystemAnalytics = async () => {
  try {
    const now = new Date();
    const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const last30Days = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const transactionsRef = collection(db, 'transactions');
    
    // Get transactions for last 7 days
    const q7Days = query(
      transactionsRef,
      where('timestamp', '>=', Timestamp.fromDate(last7Days))
    );
    const snapshot7Days = await getDocs(q7Days);

    // Get transactions for last 30 days
    const q30Days = query(
      transactionsRef,
      where('timestamp', '>=', Timestamp.fromDate(last30Days))
    );
    const snapshot30Days = await getDocs(q30Days);

    let cne7Days = 0;
    let cne30Days = 0;
    const typeBreakdown = {};

    snapshot7Days.forEach(doc => {
      const data = doc.data();
      if (data.amount > 0) cne7Days += data.amount;
    });

    snapshot30Days.forEach(doc => {
      const data = doc.data();
      if (data.amount > 0) {
        cne30Days += data.amount;
        typeBreakdown[data.type] = (typeBreakdown[data.type] || 0) + data.amount;
      }
    });

    return {
      cneDistributed7Days: cne7Days,
      cneDistributed30Days: cne30Days,
      typeBreakdown,
      transactionCount7Days: snapshot7Days.size,
      transactionCount30Days: snapshot30Days.size
    };
  } catch (error) {
    console.error('Error fetching analytics:', error);
    throw error;
  }
};

/**
 * Bulk update user balances
 */
export const bulkUpdateBalances = async (updates) => {
  try {
    const batch = writeBatch(db);
    
    updates.forEach(({ userId, balance }) => {
      const userRef = doc(db, 'users', userId);
      batch.update(userRef, { balance, lastModified: Timestamp.now() });
    });

    await batch.commit();
    return { success: true, count: updates.length };
  } catch (error) {
    console.error('Error bulk updating balances:', error);
    throw error;
  }
};
