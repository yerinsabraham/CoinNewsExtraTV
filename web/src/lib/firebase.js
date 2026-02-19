import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
import { getStorage } from 'firebase/storage'
import { getAnalytics } from 'firebase/analytics'

// Firebase configuration
// Note: These should be in .env file for production
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "AIzaSyBs0l71zGqSLU-F6x8c1iKkjl_cQPyHtyE",
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "coinnewsextra-tv.firebaseapp.com",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "coinnewsextra-tv",
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "coinnewsextra-tv.appspot.com",
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "123456789",
  appId: import.meta.env.VITE_FIREBASE_APP_ID || "1:123456789:web:abcdef",
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID || "G-XXXXXXXXXX"
}

// Initialize Firebase
const app = initializeApp(firebaseConfig)

// Initialize Firebase services
export const auth = getAuth(app)
export const db = getFirestore(app)
export const storage = getStorage(app)

// Initialize Analytics only in browser environment
let analytics = null
if (typeof window !== 'undefined') {
  try {
    analytics = getAnalytics(app)
  } catch (error) {
    console.warn('Analytics not initialized:', error)
  }
}

export { analytics }
export default app
