import { doc, setDoc, getDoc, updateDoc } from 'firebase/firestore';
import { db } from './firebase';

/**
 * Grant admin privileges to a specific user by email
 * This should only be called by existing admins or during initial setup
 */
export const grantAdminRole = async (email) => {
  try {
    // First, we need to find the user by email
    // Since we can't query auth users directly from client, 
    // we'll need to use a different approach
    
    // For now, this will create/update a document with admin role
    // The actual user will get admin role when they sign in
    const adminEmailsRef = doc(db, 'system_config', 'admin_emails');
    const adminEmailsDoc = await getDoc(adminEmailsRef);
    
    let adminEmails = [];
    if (adminEmailsDoc.exists()) {
      adminEmails = adminEmailsDoc.data().emails || [];
    }
    
    if (!adminEmails.includes(email)) {
      adminEmails.push(email);
      await setDoc(adminEmailsRef, {
        emails: adminEmails,
        updatedAt: new Date().toISOString()
      }, { merge: true });
      
      console.log(`✅ Admin privilege granted to: ${email}`);
      return { success: true, message: `Admin privilege granted to ${email}` };
    } else {
      console.log(`ℹ️ ${email} already has admin privileges`);
      return { success: true, message: `${email} already has admin privileges` };
    }
  } catch (error) {
    console.error('Error granting admin role:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Set admin role directly on user document (if you know the user ID)
 */
export const setUserAdminRole = async (userId, isAdmin = true) => {
  try {
    const userRef = doc(db, 'users', userId);
    await updateDoc(userRef, {
      role: 'admin',
      isAdmin: isAdmin,
      updatedAt: new Date().toISOString()
    });
    
    console.log(`✅ Admin role set for user: ${userId}`);
    return { success: true, message: `Admin role set for user ${userId}` };
  } catch (error) {
    console.error('Error setting admin role:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Initialize admin for specific email on their next login
 * This creates a pending admin assignment
 */
export const initializeAdminForEmail = async (email) => {
  try {
    const pendingAdminRef = doc(db, 'pending_admin_grants', email);
    await setDoc(pendingAdminRef, {
      email: email,
      grantedAt: new Date().toISOString(),
      status: 'pending',
      role: 'admin'
    });
    
    console.log(`✅ Admin privileges queued for: ${email}`);
    return { 
      success: true, 
      message: `Admin privileges will be granted to ${email} on next login` 
    };
  } catch (error) {
    console.error('Error initializing admin:', error);
    return { success: false, error: error.message };
  }
};
