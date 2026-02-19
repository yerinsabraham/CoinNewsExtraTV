import { create } from 'zustand'
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  GoogleAuthProvider,
  signInWithPopup,
  updateProfile
} from 'firebase/auth'
import { doc, setDoc, getDoc, serverTimestamp } from 'firebase/firestore'
import { auth, db } from '../lib/firebase'
import toast from 'react-hot-toast'

export const useAuthStore = create((set, get) => ({
  user: null,
  loading: true,
  error: null,

  // Initialize auth state listener
  initializeAuth: () => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          // Fetch user data from Firestore
          const userDocRef = doc(db, 'users', firebaseUser.uid)
          const userDoc = await getDoc(userDocRef)
          
          const userData = {
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName || userDoc.data()?.displayName || 'User',
            photoURL: firebaseUser.photoURL || userDoc.data()?.photoURL || null,
            ...userDoc.data(),
          }
          
          set({ user: userData, loading: false, error: null })
        } catch (error) {
          console.error('Error fetching user data:', error)
          set({ 
            user: {
              uid: firebaseUser.uid,
              email: firebaseUser.email,
              displayName: firebaseUser.displayName || 'User',
              photoURL: firebaseUser.photoURL,
            }, 
            loading: false 
          })
        }
      } else {
        set({ user: null, loading: false, error: null })
      }
    })

    return unsubscribe
  },

  // Sign in with email and password
  signIn: async (email, password) => {
    try {
      set({ loading: true, error: null })
      const userCredential = await signInWithEmailAndPassword(auth, email, password)
      toast.success('Welcome back!')
      return { success: true, user: userCredential.user }
    } catch (error) {
      const errorMessage = error.code === 'auth/invalid-credential'
        ? 'Invalid email or password'
        : error.message
      set({ error: errorMessage, loading: false })
      toast.error(errorMessage)
      return { success: false, error: errorMessage }
    }
  },

  // Sign up with email and password
  signUp: async (email, password, displayName) => {
    try {
      set({ loading: true, error: null })
      
      // Create user account
      const userCredential = await createUserWithEmailAndPassword(auth, email, password)
      const user = userCredential.user

      // Update profile with display name
      await updateProfile(user, { displayName })

      // Create user document in Firestore
      await setDoc(doc(db, 'users', user.uid), {
        uid: user.uid,
        email: user.email,
        displayName: displayName,
        photoURL: null,
        cneTokens: 1000, // Initial tokens
        hederaAccountId: null,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      })

      toast.success('Account created successfully!')
      return { success: true, user }
    } catch (error) {
      const errorMessage = error.code === 'auth/email-already-in-use'
        ? 'Email already in use'
        : error.message
      set({ error: errorMessage, loading: false })
      toast.error(errorMessage)
      return { success: false, error: errorMessage }
    }
  },

  // Sign in with Google
  signInWithGoogle: async () => {
    try {
      set({ loading: true, error: null })
      const provider = new GoogleAuthProvider()
      const userCredential = await signInWithPopup(auth, provider)
      const user = userCredential.user

      // Check if user document exists, if not create it
      const userDocRef = doc(db, 'users', user.uid)
      const userDoc = await getDoc(userDocRef)

      if (!userDoc.exists()) {
        await setDoc(userDocRef, {
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoURL: user.photoURL,
          cneTokens: 1000,
          hederaAccountId: null,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        })
      }

      toast.success('Welcome!')
      return { success: true, user }
    } catch (error) {
      const errorMessage = error.message
      set({ error: errorMessage, loading: false })
      toast.error(errorMessage)
      return { success: false, error: errorMessage }
    }
  },

  // Sign out
  signOut: async () => {
    try {
      await signOut(auth)
      set({ user: null, error: null })
      toast.success('Signed out successfully')
      return { success: true }
    } catch (error) {
      toast.error('Error signing out')
      return { success: false, error: error.message }
    }
  },

  // Update user profile
  updateUser: (userData) => {
    set((state) => ({ 
      user: { ...state.user, ...userData } 
    }))
  },
}))
