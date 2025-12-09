import { 
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInWithPopup,
  signOut,
  updateProfile
} from 'firebase/auth';
import { doc, setDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { auth, googleProvider, db } from './firebase';

export const authService = {
  async signInWithEmail(email, password) {
    return await signInWithEmailAndPassword(auth, email, password);
  },

  async signUpWithEmail(email, password, displayName) {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    await updateProfile(userCredential.user, { displayName });
    
    // Create user document in Firestore
    await setDoc(doc(db, 'users', userCredential.user.uid), {
      uid: userCredential.user.uid,
      email: email,
      displayName: displayName,
      cneBalance: 700,
      totalBalance: 700,
      unlockedBalance: 700,
      lockedBalance: 0,
      totalEarnings: 700,
      referralCode: this.generateReferralCode(userCredential.user.uid),
      createdAt: serverTimestamp()
    });

    return userCredential;
  },

  async signInWithGoogle() {
    const userCredential = await signInWithPopup(auth, googleProvider);
    
    // Check if user document exists
    const userDoc = await getDoc(doc(db, 'users', userCredential.user.uid));
    
    if (!userDoc.exists()) {
      // Create user document for new Google users
      await setDoc(doc(db, 'users', userCredential.user.uid), {
        uid: userCredential.user.uid,
        email: userCredential.user.email,
        displayName: userCredential.user.displayName,
        cneBalance: 700,
        totalBalance: 700,
        unlockedBalance: 700,
        lockedBalance: 0,
        totalEarnings: 700,
        referralCode: this.generateReferralCode(userCredential.user.uid),
        createdAt: serverTimestamp()
      });
    }

    return userCredential;
  },

  async logout() {
    return await signOut(auth);
  },

  generateReferralCode(uid) {
    return uid.substring(0, 8).toUpperCase();
  }
};
