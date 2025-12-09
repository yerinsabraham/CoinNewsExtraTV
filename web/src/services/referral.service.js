import { db } from './firebase';
import { 
  doc, 
  getDoc, 
  setDoc, 
  updateDoc, 
  collection,
  query,
  where,
  getDocs,
  increment,
  serverTimestamp
} from 'firebase/firestore';

/**
 * Referral Service
 * Manages referral codes and rewards
 */

const REFERRAL_BONUS = 100; // CNE bonus for successful referral
const REFEREE_BONUS = 50; // CNE bonus for person who uses referral code

/**
 * Generate unique referral code for user
 */
export function generateReferralCode(userId, displayName) {
  // Create code from first 3 letters of name + last 4 digits of userId
  const namePrefix = (displayName || 'USER').substring(0, 3).toUpperCase();
  const userSuffix = userId.substring(userId.length - 4);
  return `${namePrefix}${userSuffix}`;
}

/**
 * Initialize referral code for new user
 */
export async function initializeReferralCode(userId, displayName) {
  try {
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    
    if (!userDoc.exists()) {
      throw new Error('User not found');
    }
    
    const userData = userDoc.data();
    
    // Check if user already has a referral code
    if (userData.referralCode) {
      return userData.referralCode;
    }
    
    // Generate new referral code
    const referralCode = generateReferralCode(userId, displayName);
    
    // Update user with referral code
    await updateDoc(userRef, {
      referralCode,
      referralStats: {
        totalReferrals: 0,
        totalEarned: 0,
        activeReferrals: 0
      },
      updatedAt: serverTimestamp()
    });
    
    // Create referral code document
    await setDoc(doc(db, 'referralCodes', referralCode), {
      userId,
      userName: displayName,
      code: referralCode,
      createdAt: serverTimestamp()
    });
    
    return referralCode;
  } catch (error) {
    console.error('Error initializing referral code:', error);
    throw error;
  }
}

/**
 * Apply referral code when user signs up
 */
export async function applyReferralCode(newUserId, referralCode) {
  try {
    if (!referralCode || !referralCode.trim()) {
      return null;
    }
    
    // Check if referral code exists
    const codeRef = doc(db, 'referralCodes', referralCode.toUpperCase());
    const codeDoc = await getDoc(codeRef);
    
    if (!codeDoc.exists()) {
      throw new Error('Invalid referral code');
    }
    
    const codeData = codeDoc.data();
    const referrerId = codeData.userId;
    
    // Can't refer yourself
    if (referrerId === newUserId) {
      throw new Error('You cannot use your own referral code');
    }
    
    // Check if new user already used a referral code
    const newUserRef = doc(db, 'users', newUserId);
    const newUserDoc = await getDoc(newUserRef);
    
    if (newUserDoc.exists()) {
      const newUserData = newUserDoc.data();
      if (newUserData.referredBy) {
        throw new Error('You have already used a referral code');
      }
    }
    
    // Award bonus to referrer
    const referrerRef = doc(db, 'users', referrerId);
    const referrerDoc = await getDoc(referrerRef);
    
    if (referrerDoc.exists()) {
      const referrerData = referrerDoc.data();
      const newBalance = (referrerData.cneBalance || 0) + REFERRAL_BONUS;
      
      await updateDoc(referrerRef, {
        cneBalance: newBalance,
        totalBalance: newBalance,
        unlockedBalance: newBalance,
        totalEarnings: increment(REFERRAL_BONUS),
        'earnings.referrals': increment(REFERRAL_BONUS),
        'referralStats.totalReferrals': increment(1),
        'referralStats.totalEarned': increment(REFERRAL_BONUS),
        'referralStats.activeReferrals': increment(1),
        lastUpdated: new Date().toISOString(),
        updatedAt: serverTimestamp()
      });
      
      // Log transaction for referrer
      const referrerTransactionRef = collection(db, 'users', referrerId, 'transactions');
      await setDoc(doc(referrerTransactionRef), {
        type: 'referral_bonus',
        amount: REFERRAL_BONUS,
        description: `Referral bonus from ${newUserDoc.data().displayName || 'New user'}`,
        oldBalance: referrerData.cneBalance || 0,
        newBalance,
        status: 'completed',
        timestamp: serverTimestamp(),
        createdAt: serverTimestamp()
      });
    }
    
    // Award bonus to new user (referee)
    if (newUserDoc.exists()) {
      const newUserData = newUserDoc.data();
      const newUserBalance = (newUserData.cneBalance || 0) + REFEREE_BONUS;
      
      await updateDoc(newUserRef, {
        referredBy: referrerId,
        referredByCode: referralCode.toUpperCase(),
        cneBalance: newUserBalance,
        totalBalance: newUserBalance,
        unlockedBalance: newUserBalance,
        totalEarnings: increment(REFEREE_BONUS),
        lastUpdated: new Date().toISOString(),
        updatedAt: serverTimestamp()
      });
      
      // Log transaction for new user
      const newUserTransactionRef = collection(db, 'users', newUserId, 'transactions');
      await setDoc(doc(newUserTransactionRef), {
        type: 'referral_bonus',
        amount: REFEREE_BONUS,
        description: 'Referral signup bonus',
        oldBalance: newUserData.cneBalance || 0,
        newBalance: newUserBalance,
        status: 'completed',
        timestamp: serverTimestamp(),
        createdAt: serverTimestamp()
      });
    }
    
    // Log the referral
    const referralsRef = collection(db, 'referrals');
    await setDoc(doc(referralsRef), {
      referrerId,
      refereeId: newUserId,
      referralCode: referralCode.toUpperCase(),
      referrerBonus: REFERRAL_BONUS,
      refereeBonus: REFEREE_BONUS,
      status: 'completed',
      createdAt: serverTimestamp()
    });
    
    return {
      success: true,
      referrerBonus: REFERRAL_BONUS,
      refereeBonus: REFEREE_BONUS
    };
  } catch (error) {
    console.error('Error applying referral code:', error);
    throw error;
  }
}

/**
 * Get user's referral statistics
 */
export async function getReferralStats(userId) {
  try {
    const userRef = doc(db, 'users', userId);
    const userDoc = await getDoc(userRef);
    
    if (!userDoc.exists()) {
      throw new Error('User not found');
    }
    
    const userData = userDoc.data();
    
    return {
      referralCode: userData.referralCode || null,
      totalReferrals: userData.referralStats?.totalReferrals || 0,
      totalEarned: userData.referralStats?.totalEarned || 0,
      activeReferrals: userData.referralStats?.activeReferrals || 0,
      referredBy: userData.referredBy || null,
      referredByCode: userData.referredByCode || null
    };
  } catch (error) {
    console.error('Error getting referral stats:', error);
    throw error;
  }
}

/**
 * Get list of users referred by this user
 */
export async function getReferredUsers(userId) {
  try {
    const referralsRef = collection(db, 'referrals');
    const q = query(referralsRef, where('referrerId', '==', userId));
    const snapshot = await getDocs(q);
    
    const referrals = [];
    for (const docSnap of snapshot.docs) {
      const data = docSnap.data();
      
      // Get referee user data
      const refereeRef = doc(db, 'users', data.refereeId);
      const refereeDoc = await getDoc(refereeRef);
      
      if (refereeDoc.exists()) {
        const refereeData = refereeDoc.data();
        referrals.push({
          id: docSnap.id,
          userName: refereeData.displayName || 'Anonymous',
          userPhoto: refereeData.photoURL || null,
          bonus: data.referrerBonus,
          joinedAt: data.createdAt?.toDate(),
          status: data.status
        });
      }
    }
    
    return referrals;
  } catch (error) {
    console.error('Error getting referred users:', error);
    return [];
  }
}

/**
 * Get referral bonuses
 */
export function getReferralBonuses() {
  return {
    referrerBonus: REFERRAL_BONUS,
    refereeBonus: REFEREE_BONUS
  };
}
