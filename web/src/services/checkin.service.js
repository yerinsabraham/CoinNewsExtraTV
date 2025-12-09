import { db } from './firebase';
import { 
  collection, 
  doc, 
  getDoc, 
  getDocs, 
  setDoc, 
  updateDoc, 
  query, 
  where, 
  orderBy, 
  limit as firestoreLimit,
  increment,
  serverTimestamp,
  Timestamp
} from 'firebase/firestore';

/**
 * Daily Check-in Service
 * Manages daily check-ins with streak tracking and bonus rewards
 */

const BASE_REWARD = 28; // Base CNE per check-in

// Streak bonus rewards
const STREAK_BONUSES = {
  7: 50,    // 7-day streak bonus
  14: 100,  // 14-day streak bonus
  21: 150,  // 21-day streak bonus
  28: 300,  // 28-day streak bonus (full month)
  30: 500   // 30-day streak bonus
};

/**
 * Check if user has checked in today
 */
export async function hasCheckedInToday(userId) {
  try {
    const checkinDocRef = doc(db, 'users', userId, 'checkinData', 'current');
    const checkinDoc = await getDoc(checkinDocRef);
    
    if (!checkinDoc.exists()) {
      return false;
    }
    
    const data = checkinDoc.data();
    const lastCheckin = data.lastCheckin?.toDate();
    
    if (!lastCheckin) {
      return false;
    }
    
    // Check if last check-in was today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const lastCheckinDate = new Date(lastCheckin);
    lastCheckinDate.setHours(0, 0, 0, 0);
    
    return lastCheckinDate.getTime() === today.getTime();
  } catch (error) {
    console.error('Error checking daily check-in status:', error);
    return false;
  }
}

/**
 * Get user's check-in data
 */
export async function getCheckinData(userId) {
  try {
    const checkinDocRef = doc(db, 'users', userId, 'checkinData', 'current');
    const checkinDoc = await getDoc(checkinDocRef);
    
    if (!checkinDoc.exists()) {
      return {
        currentStreak: 0,
        longestStreak: 0,
        totalCheckins: 0,
        totalEarned: 0,
        lastCheckin: null,
        canCheckIn: true
      };
    }
    
    const data = checkinDoc.data();
    const canCheckIn = !(await hasCheckedInToday(userId));
    
    return {
      currentStreak: data.currentStreak || 0,
      longestStreak: data.longestStreak || 0,
      totalCheckins: data.totalCheckins || 0,
      totalEarned: data.totalEarned || 0,
      lastCheckin: data.lastCheckin?.toDate(),
      canCheckIn
    };
  } catch (error) {
    console.error('Error getting check-in data:', error);
    throw error;
  }
}

/**
 * Calculate streak based on last check-in
 */
function calculateStreak(lastCheckin, currentStreak) {
  if (!lastCheckin) {
    return 1; // First check-in
  }
  
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  yesterday.setHours(0, 0, 0, 0);
  
  const lastCheckinDate = new Date(lastCheckin);
  lastCheckinDate.setHours(0, 0, 0, 0);
  
  // If last check-in was yesterday, continue streak
  if (lastCheckinDate.getTime() === yesterday.getTime()) {
    return (currentStreak || 0) + 1;
  }
  
  // If last check-in was earlier, reset streak
  return 1;
}

/**
 * Calculate bonus reward based on streak
 */
function calculateBonusReward(streak) {
  // Check if streak matches any bonus milestone
  if (STREAK_BONUSES[streak]) {
    return STREAK_BONUSES[streak];
  }
  return 0;
}

/**
 * Process daily check-in
 */
export async function processCheckin(userId) {
  try {
    // Check if already checked in today
    const alreadyCheckedIn = await hasCheckedInToday(userId);
    
    if (alreadyCheckedIn) {
      throw new Error('You have already checked in today. Come back tomorrow!');
    }
    
    // Get current check-in data
    const checkinDocRef = doc(db, 'users', userId, 'checkinData', 'current');
    const checkinDoc = await getDoc(checkinDocRef);
    
    let currentStreak = 0;
    let longestStreak = 0;
    let totalCheckins = 0;
    let totalEarned = 0;
    let lastCheckin = null;
    
    if (checkinDoc.exists()) {
      const data = checkinDoc.data();
      currentStreak = data.currentStreak || 0;
      longestStreak = data.longestStreak || 0;
      totalCheckins = data.totalCheckins || 0;
      totalEarned = data.totalEarned || 0;
      lastCheckin = data.lastCheckin?.toDate();
    }
    
    // Calculate new streak
    const newStreak = calculateStreak(lastCheckin, currentStreak);
    const bonusReward = calculateBonusReward(newStreak);
    const totalReward = BASE_REWARD + bonusReward;
    
    // Update longest streak if needed
    const newLongestStreak = Math.max(longestStreak, newStreak);
    
    // Get user document
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    
    if (!userDoc.exists()) {
      throw new Error('User not found');
    }
    
    const userData = userDoc.data();
    const currentBalance = userData.cneBalance || 0;
    const newBalance = currentBalance + totalReward;
    
    // Update user balance and stats
    await updateDoc(userRef, {
      cneBalance: newBalance,
      totalBalance: newBalance,
      unlockedBalance: newBalance,
      totalEarnings: increment(totalReward),
      'stats.checkInsStreak': newStreak,
      'earnings.dailyCheckIn': increment(totalReward),
      lastUpdated: new Date().toISOString(),
      updatedAt: serverTimestamp()
    });
    
    // Update check-in data
    if (checkinDoc.exists()) {
      await updateDoc(checkinDocRef, {
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        totalCheckins: increment(1),
        totalEarned: increment(totalReward),
        lastCheckin: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
    } else {
      await setDoc(checkinDocRef, {
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        totalCheckins: 1,
        totalEarned: totalReward,
        lastCheckin: serverTimestamp(),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
    }
    
    // Log the check-in in history
    const historyRef = collection(db, 'users', userId, 'checkinHistory');
    await setDoc(doc(historyRef), {
      baseReward: BASE_REWARD,
      bonusReward,
      totalReward,
      streak: newStreak,
      oldBalance: currentBalance,
      newBalance,
      timestamp: serverTimestamp(),
      createdAt: serverTimestamp()
    });
    
    // Log transaction
    const transactionRef = collection(db, 'users', userId, 'transactions');
    await setDoc(doc(transactionRef), {
      type: 'daily_checkin',
      amount: totalReward,
      description: bonusReward > 0 
        ? `Daily Check-in + ${newStreak}-day streak bonus`
        : 'Daily Check-in',
      oldBalance: currentBalance,
      newBalance,
      status: 'completed',
      timestamp: serverTimestamp(),
      createdAt: serverTimestamp()
    });
    
    return {
      success: true,
      baseReward: BASE_REWARD,
      bonusReward,
      totalReward,
      streak: newStreak,
      isStreakBonus: bonusReward > 0,
      oldBalance: currentBalance,
      newBalance
    };
  } catch (error) {
    console.error('Error processing check-in:', error);
    throw error;
  }
}

/**
 * Get check-in history for user
 */
export async function getCheckinHistory(userId, limitCount = 30) {
  try {
    const historyRef = collection(db, 'users', userId, 'checkinHistory');
    const q = query(
      historyRef,
      orderBy('timestamp', 'desc'),
      firestoreLimit(limitCount)
    );
    
    const snapshot = await getDocs(q);
    const history = [];
    
    snapshot.forEach((doc) => {
      const data = doc.data();
      history.push({
        id: doc.id,
        ...data,
        timestamp: data.timestamp?.toDate()
      });
    });
    
    return history;
  } catch (error) {
    console.error('Error getting check-in history:', error);
    return [];
  }
}

/**
 * Get check-in calendar for current month
 */
export async function getCheckinCalendar(userId, year, month) {
  try {
    // Get first and last day of month
    const firstDay = new Date(year, month, 1);
    firstDay.setHours(0, 0, 0, 0);
    
    const lastDay = new Date(year, month + 1, 0);
    lastDay.setHours(23, 59, 59, 999);
    
    const historyRef = collection(db, 'users', userId, 'checkinHistory');
    const q = query(
      historyRef,
      where('timestamp', '>=', Timestamp.fromDate(firstDay)),
      where('timestamp', '<=', Timestamp.fromDate(lastDay)),
      orderBy('timestamp', 'asc')
    );
    
    const snapshot = await getDocs(q);
    const checkins = {};
    
    snapshot.forEach((doc) => {
      const data = doc.data();
      const date = data.timestamp?.toDate();
      if (date) {
        const dateKey = date.toISOString().split('T')[0];
        checkins[dateKey] = {
          id: doc.id,
          ...data,
          timestamp: date
        };
      }
    });
    
    return checkins;
  } catch (error) {
    console.error('Error getting check-in calendar:', error);
    return {};
  }
}

/**
 * Get check-in statistics
 */
export async function getCheckinStats(userId) {
  try {
    const checkinDocRef = doc(db, 'users', userId, 'checkinData', 'current');
    const checkinDoc = await getDoc(checkinDocRef);
    
    if (!checkinDoc.exists()) {
      return {
        currentStreak: 0,
        longestStreak: 0,
        totalCheckins: 0,
        totalEarned: 0,
        averageReward: BASE_REWARD
      };
    }
    
    const data = checkinDoc.data();
    
    return {
      currentStreak: data.currentStreak || 0,
      longestStreak: data.longestStreak || 0,
      totalCheckins: data.totalCheckins || 0,
      totalEarned: data.totalEarned || 0,
      averageReward: data.totalCheckins > 0 
        ? Math.round(data.totalEarned / data.totalCheckins) 
        : BASE_REWARD
    };
  } catch (error) {
    console.error('Error getting check-in stats:', error);
    return {
      currentStreak: 0,
      longestStreak: 0,
      totalCheckins: 0,
      totalEarned: 0,
      averageReward: BASE_REWARD
    };
  }
}

/**
 * Get next streak milestone
 */
export function getNextStreakMilestone(currentStreak) {
  const milestones = Object.keys(STREAK_BONUSES).map(Number).sort((a, b) => a - b);
  
  for (const milestone of milestones) {
    if (currentStreak < milestone) {
      return {
        days: milestone,
        reward: STREAK_BONUSES[milestone],
        remaining: milestone - currentStreak
      };
    }
  }
  
  return null; // All milestones achieved
}

/**
 * Get base reward amount
 */
export function getBaseReward() {
  return BASE_REWARD;
}

/**
 * Get all streak bonuses
 */
export function getStreakBonuses() {
  return STREAK_BONUSES;
}
