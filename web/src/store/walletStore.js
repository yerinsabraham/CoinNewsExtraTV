import { create } from 'zustand'

export const useWalletStore = create((set) => ({
  balance: {
    cneTokens: 0,
    hbar: 0,
  },
  transactions: [],
  loading: false,
  
  setBalance: (balance) => set({ balance }),
  
  addTransaction: (transaction) =>
    set((state) => ({
      transactions: [transaction, ...state.transactions],
    })),
  
  setTransactions: (transactions) => set({ transactions }),
  
  setLoading: (loading) => set({ loading }),
}))
