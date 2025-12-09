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
 * Spin2Earn Service
 * Manages daily spin wheel functionality with rewards from 10-1000 CNE
 */

// Reward segments with probabilities
const REWARD_SEGMENTS = [
  { value: 10, probability: 0.30, color: '#ef4444', label: '10 CNE' },    // 30% - Red
  { value: 25, probability: 0.25, color: '#f97316', label: '25 CNE' },    // 25% - Orange
  { value: 50, probability: 0.20, color: '#eab308', label: '50 CNE' },    // 20% - Yellow
  { value: 100, probability: 0.15, color: '#22c55e', label: '100 CNE' },  // 15% - Green
  { value: 250, probability: 0.07, color: '#3b82f6', label: '250 CNE' },  // 7% - Blue
  { value: 500, probability: 0.02, color: '#a855f7', label: '500 CNE' },  // 2% - Purple
  { value: 1000, probability: 0.01, color: '#ec4899', label: '1000 CNE' } // 1% - Pink
];

const DAILY_SPIN_LIMIT = 3;

/**
 * Get user's spin data for today
 */
export async function getTodaySpinData(userId) {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const spinDocRef = doc(db, 'users', userId, 'spinData', 'current');
    const spinDoc = await getDoc(spinDocRef);
    
    if (!spinDoc.exists()) {
      return {
        spinsUsed: 0,
        spinsRemaining: DAILY_SPIN_LIMIT,
        lastSpinDate: null,
        totalSpins: 0,
        totalEarned: 0
      };
    }
    
    const data = spinDoc.data();
    const lastSpinDate = data.lastSpinDate?.toDate();
    
    // Check if last spin was today
    if (lastSpinDate) {
      lastSpinDate.setHours(0, 0, 0, 0);
      
      // If last spin was not today, reset spins
      if (lastSpinDate.getTime() !== today.getTime()) {
        return {
          spinsUsed: 0,
          spinsRemaining: DAILY_SPIN_LIMIT,
          lastSpinDate: data.lastSpinDate,
          totalSpins: data.totalSpins || 0,
          totalEarned: data.totalEarned || 0
        };
      }
    }
    
    return {
      spinsUsed: data.spinsUsed || 0,
      spinsRemaining: DAILY_SPIN_LIMIT - (data.spinsUsed || 0),
      lastSpinDate: data.lastSpinDate,
      totalSpins: data.totalSpins || 0,
      totalEarned: data.totalEarned || 0
    };
  } catch (error) {
    console.error('Error getting spin data:', error);
    throw error;
  }
}

/**
 * Generate random reward based on probabilities
 */
export function generateReward() {
  const random = Math.random();
  let cumulativeProbability = 0;
  
  for (const segment of REWARD_SEGMENTS) {
    cumulativeProbability += segment.probability;
    if (random <= cumulativeProbability) {
      return segment;
    }
  }
  
  // Fallback to lowest reward
  return REWARD_SEGMENTS[0];
}

/**
 * Process a spin and award CNE
 */
export async function processSpin(userId) {
  try {
    // Check if user has spins remaining
    const spinData = await getTodaySpinData(userId);
    
    if (spinData.spinsRemaining <= 0) {
      throw new Error('No spins remaining today. Come back tomorrow!');
    }
    
    // Generate reward
    const reward = generateReward();
    
    // Get user document
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    
    if (!userDoc.exists()) {
      throw new Error('User not found');
    }
    
    const userData = userDoc.data();
    const currentBalance = userData.cneBalance || 0;
    const newBalance = currentBalance + reward.value;
    
    // Update user balance and stats
    await updateDoc(userRef, {
      cneBalance: newBalance,
      totalBalance: newBalance,
      unlockedBalance: newBalance,
      totalEarnings: increment(reward.value),
      'stats.spinsCompleted': increment(1),
      'earnings.spin2Earn': increment(reward.value),
      lastUpdated: new Date().toISOString(),
      updatedAt: serverTimestamp()
    });
    
    // Update spin data
    const today = new Date();
    const spinDocRef = doc(db, 'users', userId, 'spinData', 'current');
    const spinDoc = await getDoc(spinDocRef);
    
    if (spinDoc.exists()) {
      const data = spinDoc.data();
      const lastSpinDate = data.lastSpinDate?.toDate();
      let spinsUsed = 1;
      
      // Check if last spin was today
      if (lastSpinDate) {
        const lastSpinToday = new Date(lastSpinDate);
        lastSpinToday.setHours(0, 0, 0, 0);
        today.setHours(0, 0, 0, 0);
        
        if (lastSpinToday.getTime() === today.getTime()) {
          spinsUsed = (data.spinsUsed || 0) + 1;
        }
      }
      
      await updateDoc(spinDocRef, {
        spinsUsed,
        lastSpinDate: serverTimestamp(),
        totalSpins: increment(1),
        totalEarned: increment(reward.value),
        updatedAt: serverTimestamp()
      });
    } else {
      await setDoc(spinDocRef, {
        spinsUsed: 1,
        lastSpinDate: serverTimestamp(),
        totalSpins: 1,
        totalEarned: reward.value,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
    }
    
    // Log the spin in history
    const historyRef = collection(db, 'users', userId, 'spinHistory');
    await setDoc(doc(historyRef), {
      reward: reward.value,
      rewardLabel: reward.label,
      color: reward.color,
      oldBalance: currentBalance,
      newBalance,
      timestamp: serverTimestamp(),
      createdAt: serverTimestamp()
    });
    
    // Log transaction
    const transactionRef = collection(db, 'users', userId, 'transactions');
    await setDoc(doc(transactionRef), {
      type: 'spin2earn',
      amount: reward.value,
      description: `Spin2Earn reward: ${reward.label}`,
      oldBalance: currentBalance,
      newBalance,
      status: 'completed',
      timestamp: serverTimestamp(),
      createdAt: serverTimestamp()
    });
    
    return {
      success: true,
      reward,
      oldBalance: currentBalance,
      newBalance,
      spinsRemaining: spinData.spinsRemaining - 1
    };
  } catch (error) {
    console.error('Error processing spin:', error);
    throw error;
  }
}

/**
 * Get spin history for user
 */
export async function getSpinHistory(userId, limitCount = 20) {
  try {
    const historyRef = collection(db, 'users', userId, 'spinHistory');
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
    console.error('Error getting spin history:', error);
    return [];
  }
}

/**
 * Get spin statistics for user
 */
export async function getSpinStats(userId) {
  try {
    const spinDocRef = doc(db, 'users', userId, 'spinData', 'current');
    const spinDoc = await getDoc(spinDocRef);
    
    if (!spinDoc.exists()) {
      return {
        totalSpins: 0,
        totalEarned: 0,
        averageReward: 0,
        highestReward: 0
      };
    }
    
    const data = spinDoc.data();
    
    // Get highest reward from history
    const historyRef = collection(db, 'users', userId, 'spinHistory');
    const q = query(historyRef, orderBy('reward', 'desc'), firestoreLimit(1));
    const snapshot = await getDocs(q);
    
    let highestReward = 0;
    if (!snapshot.empty) {
      highestReward = snapshot.docs[0].data().reward;
    }
    
    return {
      totalSpins: data.totalSpins || 0,
      totalEarned: data.totalEarned || 0,
      averageReward: data.totalSpins > 0 ? Math.round(data.totalEarned / data.totalSpins) : 0,
      highestReward
    };
  } catch (error) {
    console.error('Error getting spin stats:', error);
    return {
      totalSpins: 0,
      totalEarned: 0,
      averageReward: 0,
      highestReward: 0
    };
  }
}

/**
 * Get reward segments configuration
 */
export function getRewardSegments() {
  return REWARD_SEGMENTS;
}

/**
 * Get daily spin limit
 */
export function getDailySpinLimit() {
  return DAILY_SPIN_LIMIT;
}

/**
 * Calculate time until next spin reset (midnight)
 */
export function getTimeUntilReset() {
  const now = new Date();
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(0, 0, 0, 0);
  
  const msUntilReset = tomorrow.getTime() - now.getTime();
  const hours = Math.floor(msUntilReset / (1000 * 60 * 60));
  const minutes = Math.floor((msUntilReset % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((msUntilReset % (1000 * 60)) / 1000);
  
  return {
    hours,
    minutes,
    seconds,
    totalMs: msUntilReset
  };
}
