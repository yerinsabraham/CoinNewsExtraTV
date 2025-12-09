import { create } from 'zustand';

export const useBalanceStore = create((set) => ({
  balance: 0,
  totalEarnings: 0,
  lockedBalance: 0,
  unlockedBalance: 0,
  
  setBalance: (data) => set({
    balance: data.totalBalance || data.cneBalance || 0,
    totalEarnings: data.totalEarnings || 0,
    lockedBalance: data.lockedBalance || 0,
    unlockedBalance: data.unlockedBalance || 0
  }),
  
  addReward: (amount) => set((state) => ({
    balance: state.balance + amount,
    unlockedBalance: state.unlockedBalance + amount,
    totalEarnings: state.totalEarnings + amount
  })),

  reset: () => set({
    balance: 0,
    totalEarnings: 0,
    lockedBalance: 0,
    unlockedBalance: 0
  })
}));
