import { 
  collection, 
  addDoc, 
  getDocs, 
  query, 
  orderBy,
  Timestamp,
  doc,
  setDoc
} from 'firebase/firestore';
import { 
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut
} from 'firebase/auth';
import { auth, db } from './firebase';
import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase';

/**
 * Account Creator Service
 * Handles bulk account creation with Hedera wallet integration
 */

/**
 * Generate random email address
 */
export const generateRandomEmail = () => {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  return `cne_user_${timestamp}_${random}@gmail.com`;
};

/**
 * Generate strong random password
 */
export const generateRandomPassword = () => {
  const length = 12;
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  let password = '';
  
  // Ensure at least one of each type
  password += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[Math.floor(Math.random() * 26)]; // Uppercase
  password += 'abcdefghijklmnopqrstuvwxyz'[Math.floor(Math.random() * 26)]; // Lowercase
  password += '0123456789'[Math.floor(Math.random() * 10)]; // Number
  password += '!@#$%^&*'[Math.floor(Math.random() * 8)]; // Special char
  
  // Fill the rest
  for (let i = password.length; i < length; i++) {
    password += charset[Math.floor(Math.random() * charset.length)];
  }
  
  // Shuffle the password
  return password.split('').sort(() => Math.random() - 0.5).join('');
};

/**
 * Create a new user account with Hedera wallet
 */
export const createBulkAccount = async (email, password) => {
  try {
    // Store current user
    const currentUser = auth.currentUser;
    
    // Create Firebase Auth account
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const newUser = userCredential.user;
    
    // Call Firebase Function to create Hedera account and set up user
    const onboardUser = httpsCallable(functions, 'onboardUser');
    
    try {
      const result = await onboardUser({
        firebaseUid: newUser.uid,
        publicKey: null // Will be generated server-side
      });
      
      const userData = result.data;
      
      // Store credentials in admin_created_accounts collection
      await addDoc(collection(db, 'admin_created_accounts'), {
        email: email,
        password: password, // Plain text storage as requested
        firebaseUid: newUser.uid,
        hederaAccountId: userData.hederaAccountId || null,
        did: userData.did || null,
        cneBalance: userData.initialBalance || 0,
        createdAt: Timestamp.now(),
        createdBy: currentUser?.uid || 'admin',
        status: 'active'
      });
      
      // Update total accounts count
      await updateAccountsCount();
      
      // Sign out the new user and restore admin session if needed
      await signOut(auth);
      if (currentUser) {
        // Admin will need to re-authenticate, but we'll handle this in the UI
      }
      
      return {
        success: true,
        email: email,
        password: password,
        firebaseUid: newUser.uid,
        hederaAccountId: userData.hederaAccountId,
        did: userData.did,
        message: 'Account created successfully with Hedera wallet'
      };
      
    } catch (functionError) {
      console.error('Hedera account creation failed:', functionError);
      
      // Fallback: Still store the account even if Hedera creation fails
      await addDoc(collection(db, 'admin_created_accounts'), {
        email: email,
        password: password,
        firebaseUid: newUser.uid,
        hederaAccountId: null,
        did: null,
        cneBalance: 0,
        createdAt: Timestamp.now(),
        createdBy: currentUser?.uid || 'admin',
        status: 'pending_hedera',
        error: functionError.message
      });
      
      await updateAccountsCount();
      await signOut(auth);
      
      return {
        success: true,
        email: email,
        password: password,
        firebaseUid: newUser.uid,
        hederaAccountId: null,
        warning: 'Account created but Hedera wallet creation failed'
      };
    }
    
  } catch (error) {
    console.error('Error creating bulk account:', error);
    throw error;
  }
};

/**
 * Get all admin-created accounts
 */
export const getAdminCreatedAccounts = async () => {
  try {
    const accountsRef = collection(db, 'admin_created_accounts');
    const q = query(accountsRef, orderBy('createdAt', 'desc'));
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.() || new Date()
    }));
  } catch (error) {
    console.error('Error fetching admin created accounts:', error);
    throw error;
  }
};

/**
 * Get total count of admin-created accounts
 */
export const getAdminAccountsCount = async () => {
  try {
    const countDoc = await getDocs(collection(db, 'admin_created_accounts'));
    return countDoc.size;
  } catch (error) {
    console.error('Error getting accounts count:', error);
    return 0;
  }
};

/**
 * Update accounts count in system stats
 */
const updateAccountsCount = async () => {
  try {
    const count = await getAdminAccountsCount();
    const statsRef = doc(db, 'system_stats', 'admin_accounts');
    await setDoc(statsRef, {
      totalCreated: count,
      lastUpdated: Timestamp.now()
    }, { merge: true });
  } catch (error) {
    console.error('Error updating accounts count:', error);
  }
};

/**
 * Export accounts as CSV
 */
export const exportAccountsAsCSV = (accounts) => {
  const headers = ['Email', 'Password', 'Firebase UID', 'Hedera Account ID', 'DID', 'CNE Balance', 'Created At', 'Status'];
  const rows = accounts.map(acc => [
    acc.email,
    acc.password,
    acc.firebaseUid,
    acc.hederaAccountId || 'N/A',
    acc.did || 'N/A',
    acc.cneBalance || 0,
    acc.createdAt?.toLocaleString() || 'N/A',
    acc.status
  ]);
  
  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
  ].join('\n');
  
  return csvContent;
};

/**
 * Download CSV file
 */
export const downloadCSV = (csvContent, filename = 'admin_accounts.csv') => {
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';
  
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

/**
 * Export accounts as TXT
 */
export const exportAccountsAsTXT = (accounts) => {
  const lines = accounts.map(acc => 
    `Email: ${acc.email}\nPassword: ${acc.password}\nFirebase UID: ${acc.firebaseUid}\nHedera Account: ${acc.hederaAccountId || 'N/A'}\nDID: ${acc.did || 'N/A'}\nCNE Balance: ${acc.cneBalance || 0}\nCreated: ${acc.createdAt?.toLocaleString() || 'N/A'}\nStatus: ${acc.status}\n${'-'.repeat(80)}`
  );
  
  return lines.join('\n\n');
};

/**
 * Download TXT file
 */
export const downloadTXT = (txtContent, filename = 'admin_accounts.txt') => {
  const blob = new Blob([txtContent], { type: 'text/plain;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';
  
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

/**
 * Copy text to clipboard
 */
export const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch (error) {
    console.error('Failed to copy to clipboard:', error);
    return false;
  }
};

/**
 * Get total users count (including admin-created)
 */
export const getTotalUsersCount = async () => {
  try {
    const usersSnapshot = await getDocs(collection(db, 'users'));
    return usersSnapshot.size;
  } catch (error) {
    console.error('Error getting total users count:', error);
    return 0;
  }
};

/**
 * Create multiple accounts in batch
 * @param {number} count - Number of accounts to create
 * @param {function} onProgress - Callback for progress updates (current, total, account)
 * @param {function} onError - Callback for individual account errors
 * @returns {Promise<Object>} Results with success/failed arrays
 */
export const createBulkAccountsBatch = async (count, onProgress = null, onError = null) => {
  const results = {
    successful: [],
    failed: [],
    total: count
  };
  
  console.log(`🚀 Starting batch creation of ${count} accounts...`);
  
  for (let i = 0; i < count; i++) {
    try {
      // Generate credentials
      const email = generateRandomEmail();
      const password = generateRandomPassword();
      
      console.log(`Creating account ${i + 1}/${count}: ${email}`);
      
      // Create account
      const result = await createBulkAccount(email, password);
      
      if (result.success) {
        results.successful.push(result);
        console.log(`✅ Account ${i + 1}/${count} created successfully`);
      } else {
        results.failed.push({ email, error: result.error });
        console.error(`❌ Account ${i + 1}/${count} failed:`, result.error);
        if (onError) onError(email, result.error);
      }
      
      // Call progress callback
      if (onProgress) {
        onProgress(i + 1, count, result);
      }
      
      // Add small delay to avoid rate limiting (500ms between accounts)
      if (i < count - 1) {
        await new Promise(resolve => setTimeout(resolve, 500));
      }
      
    } catch (error) {
      console.error(`❌ Error creating account ${i + 1}/${count}:`, error);
      results.failed.push({ 
        email: 'unknown', 
        error: error.message 
      });
      if (onError) onError('unknown', error.message);
    }
  }
  
  console.log(`\n📊 Batch creation complete:
    ✅ Successful: ${results.successful.length}
    ❌ Failed: ${results.failed.length}
    📈 Total: ${results.total}
  `);
  
  return results;
};
