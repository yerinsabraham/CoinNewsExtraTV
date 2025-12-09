import { createContext, useContext, useEffect, useState } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { doc, onSnapshot } from 'firebase/firestore';
import { auth, db } from '../services/firebase';
import { useBalanceStore } from '../stores/balanceStore';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const setBalance = useBalanceStore(state => state.setBalance);
  const resetBalance = useBalanceStore(state => state.reset);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user);
      setLoading(false);

      // Listen to user's balance in real-time
      if (user) {
        const userDocRef = doc(db, 'users', user.uid);
        const unsubscribeBalance = onSnapshot(userDocRef, (doc) => {
          if (doc.exists()) {
            const data = doc.data();
            setBalance(data);
          }
        });

        // Cleanup balance listener when user changes
        return () => unsubscribeBalance();
      } else {
        // Reset balance when user logs out
        resetBalance();
      }
    });

    return unsubscribe;
  }, [setBalance, resetBalance]);

  const value = {
    user,
    loading
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
