import { 
  collection, 
  query, 
  orderBy, 
  limit, 
  getDocs,
  where,
  Timestamp 
} from 'firebase/firestore';
import { db } from './firebase';

// Time periods for leaderboard filters
export const TIME_PERIODS = {
  DAILY: 'daily',
  WEEKLY: 'weekly',
  MONTHLY: 'monthly',
  ALL_TIME: 'all_time'
};

/**
 * Get start timestamp for time period
 */
const getStartTimestamp = (period) => {
  const now = new Date();
  const startDate = new Date();

  switch (period) {
    case TIME_PERIODS.DAILY:
      startDate.setHours(0, 0, 0, 0);
      break;
    case TIME_PERIODS.WEEKLY:
      const day = startDate.getDay();
      const diff = startDate.getDate() - day + (day === 0 ? -6 : 1); // Monday
      startDate.setDate(diff);
      startDate.setHours(0, 0, 0, 0);
      break;
    case TIME_PERIODS.MONTHLY:
      startDate.setDate(1);
      startDate.setHours(0, 0, 0, 0);
      break;
    case TIME_PERIODS.ALL_TIME:
      return null;
    default:
      return null;
  }

  return Timestamp.fromDate(startDate);
};

/**
 * Calculate earnings for a time period from transactions
 */
const calculateEarningsFromTransactions = async (userId, startTimestamp) => {
  try {
    const transactionsRef = collection(db, 'transactions');
    let q;

    if (startTimestamp) {
      q = query(
        transactionsRef,
        where('userId', '==', userId),
        where('type', 'in', ['video_reward', 'quiz_reward', 'spin_reward', 'checkin_reward', 'chat_reward', 'referral_bonus']),
        where('timestamp', '>=', startTimestamp),
        orderBy('timestamp', 'desc')
      );
    } else {
      q = query(
        transactionsRef,
        where('userId', '==', userId),
        where('type', 'in', ['video_reward', 'quiz_reward', 'spin_reward', 'checkin_reward', 'chat_reward', 'referral_bonus']),
        orderBy('timestamp', 'desc')
      );
    }

    const snapshot = await getDocs(q);
    let totalEarnings = 0;

    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.amount > 0) {
        totalEarnings += data.amount;
      }
    });

    return totalEarnings;
  } catch (error) {
    console.error('Error calculating earnings:', error);
    return 0;
  }
};

/**
 * Get leaderboard data for specified time period
 */
export const getLeaderboard = async (period = TIME_PERIODS.ALL_TIME, limitCount = 50) => {
  try {
    const usersRef = collection(db, 'users');
    const usersSnapshot = await getDocs(usersRef);
    
    const startTimestamp = getStartTimestamp(period);
    const leaderboardData = [];

    // Calculate earnings for each user
    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userId = userDoc.id;

      let earnings;
      if (period === TIME_PERIODS.ALL_TIME) {
        // For all-time, use totalEarned from user document
        earnings = userData.totalEarned || 0;
      } else {
        // For specific periods, calculate from transactions
        earnings = await calculateEarningsFromTransactions(userId, startTimestamp);
      }

      if (earnings > 0) {
        leaderboardData.push({
          userId,
          displayName: userData.displayName || 'Anonymous',
          email: userData.email,
          photoURL: userData.photoURL || null,
          earnings: earnings,
          balance: userData.balance || 0,
          // Additional stats for display
          videosWatched: userData.videosWatched || 0,
          quizzesCompleted: userData.quizzesCompleted || 0,
          totalSpins: userData.totalSpins || 0,
          checkInStreak: userData.checkInStreak || 0
        });
      }
    }

    // Sort by earnings (descending) and limit results
    leaderboardData.sort((a, b) => b.earnings - a.earnings);
    const topUsers = leaderboardData.slice(0, limitCount);

    // Add rank to each user
    return topUsers.map((user, index) => ({
      ...user,
      rank: index + 1
    }));
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    throw error;
  }
};

/**
 * Get user's rank for specified time period
 */
export const getUserRank = async (userId, period = TIME_PERIODS.ALL_TIME) => {
  try {
    const leaderboard = await getLeaderboard(period, 1000); // Get more users to find rank
    const userEntry = leaderboard.find(entry => entry.userId === userId);
    
    if (userEntry) {
      return {
        rank: userEntry.rank,
        earnings: userEntry.earnings,
        totalUsers: leaderboard.length
      };
    }

    return {
      rank: null,
      earnings: 0,
      totalUsers: leaderboard.length
    };
  } catch (error) {
    console.error('Error fetching user rank:', error);
    throw error;
  }
};

/**
 * Get top N users for quick display
 */
export const getTopUsers = async (count = 10, period = TIME_PERIODS.ALL_TIME) => {
  return await getLeaderboard(period, count);
};

/**
 * Format rank with medal emoji
 */
export const formatRank = (rank) => {
  switch (rank) {
    case 1:
      return '🥇';
    case 2:
      return '🥈';
    case 3:
      return '🥉';
    default:
      return `#${rank}`;
  }
};

/**
 * Get rank color class
 */
export const getRankColorClass = (rank) => {
  switch (rank) {
    case 1:
      return 'text-yellow-400';
    case 2:
      return 'text-gray-300';
    case 3:
      return 'text-amber-600';
    default:
      return 'text-gray-400';
  }
};

/**
 * Format earnings with K/M suffix
 */
export const formatEarnings = (amount) => {
  if (amount >= 1000000) {
    return `${(amount / 1000000).toFixed(1)}M`;
  }
  if (amount >= 1000) {
    return `${(amount / 1000).toFixed(1)}K`;
  }
  return amount.toFixed(0);
};
